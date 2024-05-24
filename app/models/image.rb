class Image < ApplicationRecord
  has_one_attached :image

  # This method will be called to process the image
  def process_image
    return if self.image.blank? # Ensure image is present

    vision = Google::Cloud::Vision.image_annotator
    image_path = ActiveStorage::Blob.service.send(:path_for, self.image.key)

    begin
      Rails.logger.info "Starting text detection for image at path: #{image_path}"
      response = vision.text_detection image: image_path

      if response.responses.any? && response.responses[0].text_annotations.any?
        extracted_text = response.responses[0].text_annotations[0].description
        Rails.logger.info "Text detected: #{extracted_text}"
        self.update(text: extracted_text)
        process_text # Call the method to process the text
      else
        Rails.logger.info "No text detected."
        self.update(text: '<p>No text detected</p>')
      end
    rescue => e
      Rails.logger.error "Error during text extraction: #{e.message}"
      self.update(text: '<p>Error during text extraction</p>')
    end
  end

  private

  # Process the extracted text
  def process_text
    return if self.text.blank?

    paragraphs = self.text.split("\n")
    html_text = paragraphs.map { |p| "<p>#{p}</p>" }.join("")
    self.update(text: html_text)
  end
end
