import { useEffect } from "react";
import { View, Text, StyleSheet } from "react-native";
import { createLogger } from "../lib/logger";

const log = createLogger("HomeScreen");

export default function HomeScreen() {
  useEffect(() => {
    log.info("HomeScreen mounted");
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Hello World</Text>
      <Text style={styles.subtitle}>Mobile app is running</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#f3f4f6",
  },
  title: {
    fontSize: 32,
    fontWeight: "bold",
    color: "#111827",
  },
  subtitle: {
    marginTop: 8,
    fontSize: 16,
    color: "#4b5563",
  },
});
