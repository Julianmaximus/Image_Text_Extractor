class ImagesController < ApplicationController
  def new
    @image = Image.new
  end

  def create
    @image = Image.new(image_params)
    if @image.save
      extract_and_process_text(@image)
      redirect_to @image, notice: 'Image was successfully created.'
    else
      render :new
    end
  end

  def show
    @image = Image.find(params[:id])
  end

  def update
    @image = Image.find(params[:id])
    if @image.update(image_params)
      extract_and_process_text(@image)
      redirect_to @image, notice: 'Image was successfully updated.'
    else
      render :edit
    end
  end

  private

  def image_params
    params.require(:image).permit(:title, :image)
  end

  def extract_and_process_text(image)
    vision = Google::Cloud::Vision.image_annotator
    image_path = ActiveStorage::Blob.service.send(:path_for, image.image.key)
    response = vision.text_detection image: image_path

    if response.responses.any? && response.responses[0].text_annotations.any?
      extracted_text = response.responses[0].text_annotations[0].description
      image.update(text: extracted_text)
      process_text(image)
    else
      image.update(text: '<p>No text detected</p>')
    end
  end

  def process_text(image)
    return if image.text.blank?

    paragraphs = image.text.split("\n")
    html_text = paragraphs.map { |p| "<p>#{p}</p>" }.join("")
    image.update(text: html_text)
  end
end
