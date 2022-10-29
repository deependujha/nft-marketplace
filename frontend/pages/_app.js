import "../styles/globals.css";
import styles from "../styles/Home.module.css";
import { useEffect, useState } from "react";

function MyApp({ Component, pageProps }) {
  const [connected, toggleConnect] = useState(false);
  const [currAddress, updateAddress] = useState("0x");

  return (
    <>
      <div className={`my-20 ${styles.container}`}>
        <Component {...pageProps} />
      </div>
    </>
  );
}

export default MyApp;
