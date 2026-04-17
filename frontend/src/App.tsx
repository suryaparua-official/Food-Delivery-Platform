import { BrowserRouter, Routes, Route } from "react-router-dom";
import Home from "./pages/Home";
import Login from "./pages/Login";
import ProtectedRoute from "./components/protectedRote";
import PublicRoute from "./components/publicRoute";
import SelectRole from "./pages/SelectRole";
import Navbar from "./components/navbar";
import Account from "./pages/Account";
import { useAppData } from "./context/AppContext";
import Restaurant from "./pages/Restaurant";
import RestaurantPage from "./pages/RestaurantPage";
import Cart from "./pages/Cart";
import AddAddressPage from "./pages/Address";
import Checkout from "./pages/Checkout";
import PaymentSuccess from "./pages/PaymentSuccess";
import OrderSuccess from "./pages/OrderSuccess";
import Orders from "./pages/Orders";
import OrderPage from "./pages/OrderPage";
import RiderDashboard from "./pages/RiderDashboard";
import Admin from "./pages/Admin";
import Footer from "./components/footer";

const App = () => {
  const { user, loading } = useAppData();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen bg-white">
        <div className="w-12 h-12 border-4 border-red-500 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  return (
    <BrowserRouter>
      <Routes>
        {/* Seller */}
        {user?.role === "seller" && (
          <Route path="/*" element={<Restaurant />} />
        )}

        {/* Rider */}
        {user?.role === "rider" && (
          <Route path="/*" element={<RiderDashboard />} />
        )}

        {/* Admin */}
        {user?.role === "admin" && <Route path="/*" element={<Admin />} />}

        {/* Public Routes (No Navbar, No Footer) */}
        {!user && (
          <Route element={<PublicRoute />}>
            <Route path="/login" element={<Login />} />
          </Route>
        )}

        {/* Customer Protected Layout */}
        {(!user || user.role === "customer") && (
          <Route
            element={
              <div className="min-h-screen flex flex-col">
                <Navbar />

                <div className="grow">
                  <ProtectedRoute />
                </div>

                <Footer />
              </div>
            }
          >
            <Route path="/" element={<Home />} />
            <Route
              path="/paymentsuccess/:paymentId"
              element={<PaymentSuccess />}
            />
            <Route path="/orders" element={<Orders />} />
            <Route path="/order/:id" element={<OrderPage />} />
            <Route path="/ordersuccess" element={<OrderSuccess />} />
            <Route path="/address" element={<AddAddressPage />} />
            <Route path="/checkout" element={<Checkout />} />
            <Route path="/restaurant/:id" element={<RestaurantPage />} />
            <Route path="/cart" element={<Cart />} />
            <Route path="/select-role" element={<SelectRole />} />
            <Route path="/account" element={<Account />} />
          </Route>
        )}
      </Routes>
    </BrowserRouter>
  );
};

export default App;
