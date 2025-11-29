import { useEffect, useState } from "react";
import NLogo from "../components/NLogo";
import colors from "../theme/colors";
import StatCard from "../components/StatCard";
import InputGroup from "../components/InputGroup";
import Navbar from "../components/Navbar";
import LogoutButton from "../components/LogoutButton";
import {
  Award,
  CheckCircle2,
  XCircle,
  Scale,
  Ruler,
  MessageSquare,
  Calendar,
  LogOut,
  Pointer
} from "lucide-react";

export default function Account() {
  //Setup state variabes
  const [user, setUser] = useState(null); //currently logged in user
  const [nickname, setNickname] = useState(""); //stores user nickname
  const [dob, setDob] = useState(""); //stores the user's date of birth
  const [height, setHeight] = useState(""); //stores the user's height
  const [weight, setWeight] = useState(""); //stores the user's weight
  const [loading, setLoading] = useState(true); //Boolean for if the screen is loading
  const [message, setMessage] = useState(""); //Stores returned message from backend on success
  const [error, setError] = useState(""); //Stores the error returned from backend (to display to user)
  const [submiting, setSubmiting] = useState(false); //So the user can't spam submit

  //
  useEffect(() => {
    //Make a request to /account endpoint on backend
    fetch("http://localhost:5000/account", { credentials: "include" }) //send cookies (used on backend for account verification)
      .then(res => res.json()) //convert response to json
      .then(data => {
        if (data.error) { //Redirect user to /login if user not authenticated
          window.location.href = "/login";
        } else { //Using the returned json set fronend state variables accordingly
          setUser(data);
          setNickname(data.nickname || "");
          setDob(data.date_of_birth || "");
          setHeight(data.height || "");
          setWeight(data.weight || "");
        }
        setLoading(false);
      })
      .catch(() => { //Server or CORS issue (probably)
        setError("Failed to load account data");
        setLoading(false);
      });
  }, []); //run once after render

  const handleSubmit = async (e) => { //On form submission
    e.preventDefault(); //Stop browser from reloading page
    
    if (submiting) return;

    //Clear previous error or messages in UI
    setMessage(""); 
    setError("");
    setSubmiting(true);

    try {
      //Make a request to /account/update routee on backend
      const res = await fetch("http://localhost:5000/account/update", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          nickname: nickname || null,
          date_of_birth: dob || null,
          height: height || null,
          weight: weight || null,
        }),
      });

      //Convert response to JSON
      const data = await res.json();
      if (res.ok) setMessage("Account updated successfully!"); //Check result 
      else setError(data.error || "Update failed"); //Set the error if failed
    } catch { //Probably problem with CORS or server
      setError("Could not connect to backend");
    } finally {
      setSubmiting(false);
    }
  };

  const handleLogout = () => { 
    //Handle logout on backend
    fetch("http://localhost:5000/auth/logout", { credentials: "include" })
      .then(() => window.location.href = "/login"); //change screen to login (might change to home screen)
  };

  //In case backend is taking a long time to fetch data
  if (loading) return <p>Loading...</p>;

  //Page Content
  return (
    <div className="min-h-screen" style={{ backgroundColor: colors.lightGreen }}>
      <Navbar isLoggedIn={true} isSticky={true} /> {/**Add in NAvbar at top*/}

      <main className="max-w-6xl mx-auto px-6 py-10 flex flex-col gap-12">
        {/*General Announcements*/}
        <div className="bg-white p-8 rounded-2xl shadow-sm border-2 border-solid" style={{ borderColor: colors.lightGreen }}>
          <h1 className="text-4xl font-bold mb-3 tracking-tight" style={{ color: colors.textDark }}>
            Welcome back, {nickname || user.username}!
          </h1>
          {/**Make lager and add announcments here */}
          <p className="text-md opacity-70" style={{ color: colors.darkGreen }}>
            Manage your profile and track your progress.
          </p>
        </div>

        {/* STAT GRID */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          <StatCard icon={Award} iconBg="red" value="0 days" label="Current Streak" iconColor="white" />
          <StatCard icon={CheckCircle2} iconBg={colors.mint} value="Logged" label="Meals Today" iconColor={colors.sage} />
          <StatCard icon={XCircle} iconBg="#fee2e2" value="Not Logged" label="Workout Today" iconColor="#dc2626" />
          <StatCard icon={Scale} iconBg="#3b82f6" value={weight || "No Weigh In Yet"} label="Last Weight Update" iconColor="white" />
        </div>

        {/* PROFILE FORM */}
        <form className="bg-white p-8 rounded-2xl shadow-sm border flex flex-col gap-6" onSubmit={handleSubmit} style={{ borderColor: colors.lightGreen }}>
          <h2 className="text-2xl font-semibold tracking-tight" style={{ color: colors.textDark }}>
            Profile Information
          </h2>

          {message && <p className="text-green-600">{message}</p>}
          {error && <p className="text-red-600">{error}</p>}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <InputGroup label="Nickname" Icon={MessageSquare} value={nickname} onChange={(e) => setNickname(e.target.value)} placeholder = "Enter Nickname"/>
            <InputGroup label="Birthdate" Icon={Calendar} type="date" value={dob} onChange={(e) => setDob(e.target.value)} />
            <InputGroup label="Height" Icon={Ruler} type="number" value={height} onChange={(e) => setHeight(e.target.value)} unit="inches" placeholder = "Enter Height"/>
            <InputGroup label="Weight" Icon={Scale} type="number" value={weight} onChange={(e) => setWeight(e.target.value)} unit="lbs" placeholder = "Enter Weight"/>
          </div>

          {/**While submitting to the backend, disable the submit button*/}
          <button type="submit" className="mt-2 py-3 rounded-xl font-semibold transition hover:brightness-95" 
           style={{ 
            backgroundColor: colors.sage, 
            color: colors.cream,
            opacity: submiting ? 0.6 : 1,
            cursor : submiting ? "not-allowed" : "pointer"
            }}
            disabled={submiting}
            aria-busy={submiting}
            aria-disabled={submiting}
            >
              {submiting ? "Saving..." : "Save Changes"}
          </button>
        </form>

        {/* SIGN OUT */}
        <div className="flex justify-center">
          <LogoutButton />
        </div>
      </main>
    </div>
  );
}