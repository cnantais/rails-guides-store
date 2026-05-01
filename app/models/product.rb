class Product < ApplicationRecord
  include Notifications

  has_many :wishlist_products, dependent: :destroy
  has_many :wishlists, through: :wishlist_products
  has_one_attached :featured_image
  has_rich_text :description

  validates :name, presence: true
  validates :inventory_count, numericality: { greater_than_or_equal_to: 0 }
end
