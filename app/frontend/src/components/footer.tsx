import React from "react";

const Footer: React.FC = () => {
  return (
    <footer className="bg-black text-gray-300 pt-12 pb-8">
      <div className="max-w-7xl mx-auto px-6 grid grid-cols-1 md:grid-cols-4 gap-8">
        {/* Brand Section */}
        <div>
          <h2 className="text-2xl font-bold text-white mb-4">Zomato</h2>
          <p className="text-sm leading-6">
            Bringing your favorite meals from the best restaurants straight to
            your doorstep. Fast delivery. Fresh food. Reliable service.
          </p>
        </div>

        {/* Company Links */}
        <div>
          <h3 className="text-lg font-semibold text-white mb-4">Company</h3>
          <ul className="space-y-2 text-sm">
            <li>
              <a href="#" className="hover:text-white transition">
                About Us
              </a>
            </li>
            <li>
              <a href="#" className="hover:text-white transition">
                Careers
              </a>
            </li>
            <li>
              <a href="#" className="hover:text-white transition">
                Blog
              </a>
            </li>
            <li>
              <a href="#" className="hover:text-white transition">
                Press
              </a>
            </li>
          </ul>
        </div>

        {/* Support Links */}
        <div>
          <h3 className="text-lg font-semibold text-white mb-4">Support</h3>
          <ul className="space-y-2 text-sm">
            <li>
              <a href="#" className="hover:text-white transition">
                Help Center
              </a>
            </li>
            <li>
              <a href="#" className="hover:text-white transition">
                Track Order
              </a>
            </li>
            <li>
              <a href="#" className="hover:text-white transition">
                Refund Policy
              </a>
            </li>
            <li>
              <a href="#" className="hover:text-white transition">
                Privacy Policy
              </a>
            </li>
          </ul>
        </div>

        {/* Contact Section */}
        <div>
          <h3 className="text-lg font-semibold text-white mb-4">Contact</h3>
          <p className="text-sm">support@zomato.com</p>
          <p className="text-sm mt-2">+91 12345 67890</p>
          <div className="flex space-x-4 mt-4">
            <a href="#" className="hover:text-white transition">
              Facebook
            </a>
            <a href="#" className="hover:text-white transition">
              Instagram
            </a>
            <a href="#" className="hover:text-white transition">
              Twitter
            </a>
          </div>
        </div>
      </div>

      {/* Bottom Section */}
      <div className="border-t border-gray-700 mt-10 pt-6 text-center text-sm text-gray-500">
        © {new Date().getFullYear()} Zomato. All rights reserved.
      </div>
    </footer>
  );
};

export default Footer;
