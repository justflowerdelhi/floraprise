import React from "react";

interface ProductImage {
  url: string;
  order: number;
}

interface ProductImagesProps {
  images: ProductImage[];
}

const ProductImages: React.FC<ProductImagesProps> = ({ images }) => {
  if (!images || images.length === 0) {
    return <div>No images available.</div>;
  }

  // Sort images by order
  const sortedImages = [...images].sort((a, b) => a.order - b.order);

  return (
    <div className="product-images">
      {sortedImages.map((img, idx) => (
        <img
          key={img.url}
          src={img.url}
          alt={`Product image ${idx + 1}`}
          style={{ maxWidth: 120, marginRight: 8 }}
        />
      ))}
    </div>
  );
};

export default ProductImages;
