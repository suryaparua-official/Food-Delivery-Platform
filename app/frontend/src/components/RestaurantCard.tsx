import { useNavigate } from "react-router-dom";
import { BiTimeFive, BiMap } from "react-icons/bi";

type Props = {
  id: string;
  image: string;
  name: string;
  distance: string;
  deliveryTime: string;
  isOpen: boolean;
};

const RestaurantCard = ({
  id,
  image,
  name,
  distance,
  deliveryTime,
  isOpen,
}: Props) => {
  const navigate = useNavigate();

  // static for now
  const rating = "4.5";
  const reviews = "980";
  const category = "Indian";
  const openTime = "10:00 AM - 11:30 PM";

  return (
    <div
      onClick={() => navigate(`/restaurant/${id}`)}
      className="group cursor-pointer rounded-2xl bg-white shadow-sm border border-gray-100 overflow-hidden transition-all duration-300 hover:shadow-lg hover:-translate-y-1"
    >
      {/* Image */}
      <div className="relative w-full h-48 overflow-hidden">
        <img
          src={image}
          alt={name}
          className={`w-full h-full object-cover transition-transform duration-500 group-hover:scale-105 ${
            !isOpen ? "grayscale brightness-90" : ""
          }`}
        />

        {/* Open / Closed Badge */}
        <div className="absolute top-3 left-3">
          <span
            className={`px-3 py-1 text-xs font-semibold rounded-full text-white ${
              isOpen ? "bg-green-500" : "bg-red-500"
            }`}
          >
            {isOpen ? "Open" : "Closed"}
          </span>
        </div>

        {/* Center Text When Closed */}
        {!isOpen && (
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-white text-lg font-semibold">
              Currently Closed
            </span>
          </div>
        )}
      </div>

      {/* Content */}
      <div className="p-6 space-y-3">
        {/* Name + Rating */}
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-900 group-hover:text-red-500 transition-colors">
            {name}
          </h3>

          <div className="bg-green-600 text-white text-xs px-3 py-1 rounded-md font-semibold flex items-center gap-1">
            ★ {rating}
          </div>
        </div>

        {/* Category */}
        <p className="text-sm text-gray-500">{category}</p>

        {/* Tags */}
        <div className="flex flex-wrap gap-2">
          <span className="text-xs bg-gray-100 px-3 py-1 rounded-full">
            Beriyani
          </span>
          <span className="text-xs bg-gray-100 px-3 py-1 rounded-full">
            Chicken
          </span>
          <span className="text-xs bg-gray-100 px-3 py-1 rounded-full">
            Noodles
          </span>
        </div>

        {/* Time + Distance */}
        <div className="flex items-center gap-6 text-sm text-gray-600">
          <div className="flex items-center gap-1.5">
            <BiTimeFive className="h-4 w-4 text-gray-500" />
            <span className="text-green-400">{deliveryTime}</span>
          </div>

          <div className="flex items-center gap-1.5">
            <BiMap className="h-4 w-4 text-gray-500" />
            <span className="text-green-400">{distance} km</span>
          </div>
        </div>

        {/* Reviews + Open Time Same Line */}
        <p className="text-xs text-gray-400">
          {reviews} reviews · {openTime}
        </p>
      </div>
    </div>
  );
};

export default RestaurantCard;
