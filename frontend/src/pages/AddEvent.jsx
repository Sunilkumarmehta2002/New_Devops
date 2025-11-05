import { useContext, useState } from 'react';
import axios from 'axios';
import { UserContext } from '../UserContext';

export default function AddEvent() {
  const { user } = useContext(UserContext);
  const [formData, setFormData] = useState({
    owner: user ? user.name : "",
    title: "",
    optional: "",
    description: "",
    organizedBy: "",
    eventDate: "",
    eventTime: "",
    location: "",
    ticketPrice: 0,
    image: '',
    likes: 0,
  });
  const [loading, setLoading] = useState(false); // Loading state for submission

  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    setFormData((prevState) => ({ ...prevState, image: file }));
  };

  const handleChange = (e) => {
    const { name, value, files } = e.target;
    if (files) {
      setFormData((prevState) => ({ ...prevState, [name]: files[0] }));
    } else {
      setFormData((prevState) => ({ ...prevState, [name]: value }));
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setLoading(true); // Set loading state to true when submission starts

    axios
      .post("/createEvent", formData)
      .then((response) => {
        console.log("Event posted successfully:", response.data);
        setLoading(false); // Reset loading state after successful submission
      })
      .catch((error) => {
        console.error("Error posting event:", error);
        setLoading(false); // Reset loading state in case of error
      });
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-gradient-to-r from-blue-500 to-purple-600 p-10">
      <div className="w-full max-w-3xl p-10 bg-white bg-opacity-90 shadow-2xl rounded-lg">
        <h1 className="font-bold text-[36px] mb-5 text-center text-sky-700">Post an Event</h1>

        <form onSubmit={handleSubmit} className="flex flex-col gap-8">
          <div className="flex flex-col gap-5">
            {[
              { label: 'Title', name: 'title', type: 'text' },
              { label: 'Event Type', name: 'optional', type: 'text' },
              { label: 'Description', name: 'description', type: 'textarea' },
              { label: 'Organized By', name: 'organizedBy', type: 'text' },
              { label: 'Event Date', name: 'eventDate', type: 'date' },
              { label: 'Event Time', name: 'eventTime', type: 'time' },
              { label: 'Location', name: 'location', type: 'text' },
              { label: 'Ticket Price', name: 'ticketPrice', type: 'number' },
            ].map((field, index) => (
              <label key={index} className="flex flex-col text-lg font-medium text-gray-700">
                {field.label}:
                {field.type === 'textarea' ? (
                  <textarea
                    name={field.name}
                    className="rounded mt-2 p-4 ring-[#EF4444] ring-2 h-24 focus:ring-4 focus:ring-[#EF4444] border-none transition"
                    value={formData[field.name]}
                    onChange={handleChange}
                  />
                ) : (
                  <input
                    type={field.type}
                    name={field.name}
                    className="rounded mt-2 p-4 ring-[#EF4444] ring-2 h-10 focus:ring-4 focus:ring-[#EF4444] border-none transition"
                    value={formData[field.name]}
                    onChange={handleChange}
                  />
                )}
              </label>
            ))}

            <label className="flex flex-col text-lg font-medium text-gray-700">
              Image:
              <input
                type="file"
                name="image"
                className="rounded mt-2 p-4 py-10 ring-[#EF4444] ring-2 focus:ring-4 focus:ring-[#EF4444] border-none transition"
                onChange={handleImageUpload}
              />
            </label>
          </div>

          <button
            type="submit"
            className="bg-gradient-to-r from-[#EF4444] to-[#EF4444] text-white py-3 px-6 rounded-full shadow-md hover:shadow-lg transition transform hover:scale-105"
            disabled={loading}  // Disable the button while loading
          >
            {loading ? 'Submitting...' : 'Submit'}
          </button>

          {loading && (
            <div className="flex justify-center mt-4">
              <div className="spinner-border text-[#EF4444]" role="status">
                <span className="sr-only">Loading...</span>
              </div>
            </div>
          )}
        </form>
      </div>
    </div>
  );
}
