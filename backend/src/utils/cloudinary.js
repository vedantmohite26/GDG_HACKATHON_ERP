const cloudinary = require("cloudinary").v2;

// Configure Cloudinary with environment variables
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
});

/**
 * Upload a file to Cloudinary
 * @param {string} filePath Local path or buffer/stream
 * @param {object} options Cloudinary upload options (folder, public_id, etc.)
 * @returns {Promise} Cloudinary upload result
 */
const upload = async (filePath, options = {}) => {
  try {
    return await cloudinary.uploader.upload(filePath, {
      resource_type: "auto",
      ...options,
    });
  } catch (error) {
    console.error("Cloudinary Upload Error:", error);
    throw new Error("Failed to upload image to Cloudinary");
  }
};

/**
 * Delete a file from Cloudinary
 * @param {string} publicId Cloudinary public ID
 * @param {string} resourceType 'image', 'video', or 'raw'
 * @returns {Promise} Cloudinary deletion result
 */
const remove = async (publicId, resourceType = "image") => {
  try {
    return await cloudinary.uploader.destroy(publicId, {
      resource_type: resourceType,
    });
  } catch (error) {
    console.error("Cloudinary Delete Error:", error);
    throw new Error("Failed to delete image from Cloudinary");
  }
};

module.exports = {
  cloudinary,
  upload,
  remove,
};
