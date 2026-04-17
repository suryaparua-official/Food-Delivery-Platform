import { useState } from "react";
import type { IMenuItem } from "../types";
import { FiEyeOff } from "react-icons/fi";
import { BsCartPlus, BsEye } from "react-icons/bs";
import { BiTrash } from "react-icons/bi";
import { VscLoading } from "react-icons/vsc";
import axios from "axios";
import { restaurantService } from "../main";
import toast from "react-hot-toast";
import { useAppData } from "../context/AppContext";

interface MenuItemsProps {
  items: IMenuItem[];
  onItemDeleted: () => void;
  isSeller: boolean;
}

const MenuItems = ({ items, onItemDeleted, isSeller }: MenuItemsProps) => {
  const [loadingItemId, setLoadingItemId] = useState<string | null>(null);

  const handleDelete = async (itemId: string) => {
    const confirm = window.confirm("Are you sure you want to delete this item");
    if (!confirm) return;

    try {
      await axios.delete(`${restaurantService}/api/item/${itemId}`, {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
      });

      toast.success("Item deleted");
      onItemDeleted();
    } catch (error) {
      console.log(error);
      toast.error("Failed to delete item");
    }
  };

  const toggleAvailiblity = async (itemId: string) => {
    try {
      const { data } = await axios.put(
        `${restaurantService}/api/item/status/${itemId}`,
        {},
        {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("token")}`,
          },
        },
      );

      toast.success(data.message);
      onItemDeleted();
    } catch (error: unknown) {
      if (axios.isAxiosError(error)) {
        toast.error(error.response?.data?.message || "Something went wrong");
      } else {
        toast.error("Something went wrong");
      }
    }
  };

  const { fetchCart } = useAppData();

  const addToCart = async (restaurantId: string, itemId: string) => {
    try {
      setLoadingItemId(itemId);

      const { data } = await axios.post(
        `${restaurantService}/api/cart/add`,
        {
          restaurantId,
          itemId,
        },
        {
          headers: {
            Authorization: `Bearer ${localStorage.getItem("token")}`,
          },
        },
      );

      toast.success(data.message);
      fetchCart();
    } catch (error: unknown) {
      if (axios.isAxiosError(error)) {
        toast.error(error.response?.data?.message || "Something went wrong");
      } else {
        toast.error("Something went wrong");
      }
    } finally {
      setLoadingItemId(null);
    }
  };

  return (
    <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
      {items.map((item) => {
        const isLoading = loadingItemId === item._id;

        // Stable dummy rating (no review count shown)
        const dummyRating = (
          (parseInt(item._id.slice(-2), 16) % 15) / 10 +
          3.8
        ).toFixed(1);

        return (
          <div
            key={item._id}
            className={`group relative flex flex-col rounded-2xl bg-white shadow-sm border border-gray-100 transition-all duration-300 hover:shadow-lg hover:-translate-y-1 ${
              !item.isAvailable ? "opacity-70" : ""
            }`}
          >
            {/* Image */}
            <div className="relative h-40 w-full overflow-hidden rounded-t-2xl">
              <img
                src={item.image}
                alt={item.name}
                className={`h-full w-full object-cover transition-transform duration-500 group-hover:scale-110 ${
                  !item.isAvailable ? "grayscale brightness-75" : ""
                }`}
              />

              {!item.isAvailable && (
                <div className="absolute inset-0 flex items-center justify-center bg-black/60">
                  <span className="rounded-md bg-black/80 px-3 py-1 text-xs font-semibold text-white">
                    Not Available
                  </span>
                </div>
              )}

              {/* Rating Badge */}
              <div className="absolute top-3 right-3 bg-green-600 text-white text-xs px-2 py-1 rounded-md font-semibold shadow">
                {dummyRating} ★
              </div>
            </div>

            {/* Content */}
            <div className="flex flex-1 flex-col justify-between p-4">
              <div>
                <h3 className="text-base font-bold text-gray-900 truncate">
                  {item.name}
                </h3>

                {item.description && (
                  <p className="mt-1 text-sm text-gray-500 line-clamp-2">
                    {item.description}
                  </p>
                )}
              </div>

              <div className="mt-4 flex items-center justify-between">
                <p className="text-lg font-semibold text-gray-900">
                  ₹{item.price}
                </p>

                {isSeller && (
                  <div className="flex gap-2">
                    <button
                      onClick={() => toggleAvailiblity(item._id)}
                      className="rounded-lg p-2 text-gray-600 hover:bg-gray-100 transition"
                    >
                      {item.isAvailable ? (
                        <BsEye size={18} />
                      ) : (
                        <FiEyeOff size={18} />
                      )}
                    </button>

                    <button
                      onClick={() => handleDelete(item._id)}
                      className="rounded-lg p-2 text-red-500 hover:bg-red-50 transition"
                    >
                      <BiTrash size={18} />
                    </button>
                  </div>
                )}

                {!isSeller && (
                  <button
                    disabled={!item.isAvailable || isLoading}
                    onClick={() => addToCart(item.restaurantId, item._id)}
                    className={`flex items-center justify-center rounded-lg px-3 py-2 text-sm font-medium transition ${
                      !item.isAvailable || isLoading
                        ? "cursor-not-allowed bg-gray-100 text-gray-400"
                        : "bg-red-500 text-white hover:bg-red-600"
                    }`}
                  >
                    {isLoading ? (
                      <VscLoading size={18} className="animate-spin" />
                    ) : (
                      <>
                        <BsCartPlus className="mr-1" size={16} />
                        Add
                      </>
                    )}
                  </button>
                )}
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
};

export default MenuItems;
