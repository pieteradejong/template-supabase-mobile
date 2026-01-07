import { useEffect, useState, useCallback, useRef } from "react";
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  ActivityIndicator,
  TouchableOpacity,
  RefreshControl,
  Modal,
  TextInput,
  Alert,
  KeyboardAvoidingView,
  ScrollView,
  Keyboard,
  Platform,
} from "react-native";
import type { Tables } from "@acme/types";
import { supabase } from "../lib/supabase";
import { createLogger } from "../lib/logger";

const log = createLogger("HomeScreen");

type Item = Tables<"items">;

function getErrorMessage(err: unknown): string {
  if (err instanceof Error) {
    return err.message;
  }

  // Supabase errors (PostgrestError, AuthError) commonly have a string `message`
  if (typeof err === "object" && err !== null && "message" in err) {
    const maybeMessage = (err as { message?: unknown }).message;
    if (typeof maybeMessage === "string" && maybeMessage.trim().length > 0) {
      // Common misconfiguration: SUPABASE_URL points at the Supabase dashboard
      // instead of the project API URL (https://<ref>.supabase.co).
      if (
        maybeMessage.includes("<!DOCTYPE html") &&
        (maybeMessage.includes("Supabase Studio") ||
          maybeMessage.includes("/dashboard/") ||
          maybeMessage.includes("We couldn't find the page"))
      ) {
        return "Your Supabase URL looks wrong (it points to the dashboard). Set EXPO_PUBLIC_SUPABASE_URL to your Project URL like: https://<project-ref>.supabase.co";
      }

      return maybeMessage;
    }
  }

  return "Failed to fetch items";
}

export default function HomeScreen() {
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [newDescription, setNewDescription] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const descriptionInputRef = useRef<TextInput>(null);

  const fetchItems = useCallback(async () => {
    try {
      log.info("Fetching items from Supabase...");

      const { data, error: fetchError } = await supabase
        .from("items")
        .select("*")
        .order("created_at", { ascending: false });

      if (fetchError) {
        throw fetchError;
      }

      log.info(`Fetched ${data?.length ?? 0} items`);
      setItems(data ?? []);
      setError(null);
    } catch (err) {
      const message = getErrorMessage(err);
      log.error(
        "Error fetching items",
        err instanceof Error ? err : { error: err, resolvedMessage: message }
      );
      setError(message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    log.info("HomeScreen mounted");
    fetchItems();
  }, [fetchItems]);

  const onRefresh = useCallback(() => {
    setRefreshing(true);
    fetchItems();
  }, [fetchItems]);

  const insertItem = useCallback(
    async (title: string, description?: string): Promise<Item | null> => {
      try {
        log.info("Creating item", { title, hasDescription: !!description });

        const { data, error: insertError } = await supabase
          .from("items")
          .insert({ title, description: description || null })
          .select("*")
          .single();

        if (insertError) {
          throw insertError;
        }

        if (!data) {
          throw new Error("No data returned from insert");
        }

        log.info("Item created successfully", { id: data.id, title: data.title });
        return data;
      } catch (err) {
        const message = getErrorMessage(err);
        log.error(
          "Error creating item",
          err instanceof Error ? err : { error: err, resolvedMessage: message }
        );
        throw new Error(message);
      }
    },
    []
  );

  const deleteItemById = useCallback(async (id: string): Promise<void> => {
    try {
      log.info("Deleting item", { id });

      const { error: deleteError } = await supabase.from("items").delete().eq("id", id);

      if (deleteError) {
        throw deleteError;
      }

      log.info("Item deleted successfully", { id });
    } catch (err) {
      const message = getErrorMessage(err);
      log.error(
        "Error deleting item",
        err instanceof Error ? err : { error: err, resolvedMessage: message }
      );
      throw new Error(message);
    }
  }, []);

  const handleCreateItem = useCallback(async () => {
    const trimmedTitle = newTitle.trim();
    if (!trimmedTitle) {
      Alert.alert("Validation Error", "Title is required");
      return;
    }

    setSubmitting(true);
    try {
      const newItem = await insertItem(trimmedTitle, newDescription.trim() || undefined);
      if (newItem) {
        // Optimistically prepend the new item to the list
        setItems((prev) => [newItem, ...prev]);
        setCreateModalOpen(false);
        setNewTitle("");
        setNewDescription("");
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : "Failed to create item";
      Alert.alert("Error", message);
    } finally {
      setSubmitting(false);
    }
  }, [newTitle, newDescription, insertItem]);

  const handleDeleteItem = useCallback(
    (item: Item) => {
      Alert.alert("Delete Item", `Are you sure you want to delete "${item.title}"?`, [
        { text: "Cancel", style: "cancel" },
        {
          text: "Delete",
          style: "destructive",
          onPress: async () => {
            try {
              await deleteItemById(item.id);
              // Optimistically remove the item from the list
              setItems((prev) => prev.filter((i) => i.id !== item.id));
            } catch (err) {
              const message = err instanceof Error ? err.message : "Failed to delete item";
              Alert.alert("Error", message);
            }
          },
        },
      ]);
    },
    [deleteItemById]
  );

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color="#3b82f6" />
        <Text style={styles.loadingText}>Loading items...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.centered}>
        <Text style={styles.errorTitle}>Connection Error</Text>
        <Text style={styles.errorText}>{error}</Text>
        <Text style={styles.hint}>
          Check your Supabase config:{"\n"}- EXPO_PUBLIC_SUPABASE_URL{"\n"}-
          EXPO_PUBLIC_SUPABASE_ANON_KEY{"\n\n"}
          If you are using local Supabase:{"\n"}
          supabase start
        </Text>
        <TouchableOpacity style={styles.retryButton} onPress={fetchItems}>
          <Text style={styles.retryButtonText}>Retry</Text>
        </TouchableOpacity>
      </View>
    );
  }

  if (items.length === 0) {
    return (
      <View style={styles.container}>
        <View style={styles.header}>
          <View style={styles.headerRow}>
            <View style={styles.headerText}>
              <Text style={styles.title}>Items</Text>
              <Text style={styles.subtitle}>No items yet</Text>
            </View>
            <TouchableOpacity
              style={styles.addButton}
              onPress={() => setCreateModalOpen(true)}
              accessibilityLabel="Add new item"
            >
              <Text style={styles.addButtonText}>+</Text>
            </TouchableOpacity>
          </View>
        </View>
        <View style={styles.centered}>
          <Text style={styles.emptyTitle}>No Items Yet</Text>
          <Text style={styles.emptyText}>Tap the + button to create your first item.</Text>
          <TouchableOpacity style={styles.retryButton} onPress={() => setCreateModalOpen(true)}>
            <Text style={styles.retryButtonText}>Create Item</Text>
          </TouchableOpacity>
        </View>
        <Modal
          visible={createModalOpen}
          animationType="slide"
          transparent={true}
          onRequestClose={() => {
            Keyboard.dismiss();
            setCreateModalOpen(false);
          }}
        >
          <TouchableOpacity
            style={styles.modalOverlay}
            activeOpacity={1}
            onPress={() => Keyboard.dismiss()}
          >
            <TouchableOpacity
              activeOpacity={1}
              onPress={(e) => e.stopPropagation()}
              style={styles.modalTouchableContent}
            >
              <KeyboardAvoidingView
                behavior={Platform.OS === "ios" ? "padding" : "height"}
                keyboardVerticalOffset={Platform.OS === "ios" ? 0 : 20}
                style={styles.keyboardAvoidingView}
              >
                <ScrollView
                  contentContainerStyle={styles.modalScrollContent}
                  keyboardShouldPersistTaps="handled"
                  showsVerticalScrollIndicator={false}
                >
                  <View style={styles.modalContent}>
                    <Text style={styles.modalTitle}>Create New Item</Text>

                    <Text style={styles.inputLabel}>Title *</Text>
                    <TextInput
                      style={styles.input}
                      value={newTitle}
                      onChangeText={setNewTitle}
                      placeholder="Enter item title"
                      autoFocus
                      editable={!submitting}
                      returnKeyType="done"
                      blurOnSubmit={true}
                      onSubmitEditing={() => {
                        if (!newDescription.trim()) {
                          handleCreateItem();
                        } else {
                          descriptionInputRef.current?.focus();
                        }
                      }}
                    />

                    <Text style={styles.inputLabel}>Description (optional)</Text>
                    <TextInput
                      ref={descriptionInputRef}
                      style={[styles.input, styles.textArea]}
                      value={newDescription}
                      onChangeText={setNewDescription}
                      placeholder="Enter item description"
                      multiline
                      numberOfLines={3}
                      editable={!submitting}
                      returnKeyType="default"
                      blurOnSubmit={true}
                    />

                    <View style={styles.modalButtons}>
                      <TouchableOpacity
                        style={[styles.modalButton, styles.cancelButton]}
                        onPress={() => {
                          Keyboard.dismiss();
                          setCreateModalOpen(false);
                          setNewTitle("");
                          setNewDescription("");
                        }}
                        disabled={submitting}
                      >
                        <Text style={styles.cancelButtonText}>Cancel</Text>
                      </TouchableOpacity>
                      <TouchableOpacity
                        style={[
                          styles.modalButton,
                          styles.createButton,
                          submitting && styles.disabledButton,
                        ]}
                        onPress={handleCreateItem}
                        disabled={submitting}
                      >
                        {submitting ? (
                          <ActivityIndicator size="small" color="#ffffff" />
                        ) : (
                          <Text style={styles.createButtonText}>Create</Text>
                        )}
                      </TouchableOpacity>
                    </View>
                  </View>
                </ScrollView>
              </KeyboardAvoidingView>
            </TouchableOpacity>
          </TouchableOpacity>
        </Modal>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View style={styles.headerRow}>
          <View style={styles.headerText}>
            <Text style={styles.title}>Items</Text>
            <Text style={styles.subtitle}>
              {items.length} item{items.length !== 1 ? "s" : ""} from Supabase
            </Text>
          </View>
          <TouchableOpacity
            style={styles.addButton}
            onPress={() => setCreateModalOpen(true)}
            accessibilityLabel="Add new item"
          >
            <Text style={styles.addButtonText}>+</Text>
          </TouchableOpacity>
        </View>
      </View>

      <FlatList
        data={items}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.list}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.card}
            onLongPress={() => handleDeleteItem(item)}
            activeOpacity={0.7}
          >
            <Text style={styles.cardTitle}>{item.title}</Text>
            {item.description ? (
              <Text style={styles.cardDescription}>{item.description}</Text>
            ) : null}
            <Text style={styles.cardDate}>{new Date(item.created_at).toLocaleDateString()}</Text>
          </TouchableOpacity>
        )}
      />

      <Modal
        visible={createModalOpen}
        animationType="slide"
        transparent={true}
        onRequestClose={() => {
          Keyboard.dismiss();
          setCreateModalOpen(false);
        }}
      >
        <TouchableOpacity
          style={styles.modalOverlay}
          activeOpacity={1}
          onPress={() => Keyboard.dismiss()}
        >
          <TouchableOpacity
            activeOpacity={1}
            onPress={(e) => e.stopPropagation()}
            style={styles.modalTouchableContent}
          >
            <KeyboardAvoidingView
              behavior={Platform.OS === "ios" ? "padding" : "height"}
              keyboardVerticalOffset={Platform.OS === "ios" ? 0 : 20}
              style={styles.keyboardAvoidingView}
            >
              <ScrollView
                contentContainerStyle={styles.modalScrollContent}
                keyboardShouldPersistTaps="handled"
                showsVerticalScrollIndicator={false}
              >
                <View style={styles.modalContent}>
                  <Text style={styles.modalTitle}>Create New Item</Text>

                  <Text style={styles.inputLabel}>Title *</Text>
                  <TextInput
                    style={styles.input}
                    value={newTitle}
                    onChangeText={setNewTitle}
                    placeholder="Enter item title"
                    autoFocus
                    editable={!submitting}
                    returnKeyType="done"
                    blurOnSubmit={true}
                    onSubmitEditing={() => {
                      if (!newDescription.trim()) {
                        handleCreateItem();
                      } else {
                        descriptionInputRef.current?.focus();
                      }
                    }}
                  />

                  <Text style={styles.inputLabel}>Description (optional)</Text>
                  <TextInput
                    ref={descriptionInputRef}
                    style={[styles.input, styles.textArea]}
                    value={newDescription}
                    onChangeText={setNewDescription}
                    placeholder="Enter item description"
                    multiline
                    numberOfLines={3}
                    editable={!submitting}
                    returnKeyType="default"
                    blurOnSubmit={true}
                  />

                  <View style={styles.modalButtons}>
                    <TouchableOpacity
                      style={[styles.modalButton, styles.cancelButton]}
                      onPress={() => {
                        Keyboard.dismiss();
                        setCreateModalOpen(false);
                        setNewTitle("");
                        setNewDescription("");
                      }}
                      disabled={submitting}
                    >
                      <Text style={styles.cancelButtonText}>Cancel</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                      style={[
                        styles.modalButton,
                        styles.createButton,
                        submitting && styles.disabledButton,
                      ]}
                      onPress={handleCreateItem}
                      disabled={submitting}
                    >
                      {submitting ? (
                        <ActivityIndicator size="small" color="#ffffff" />
                      ) : (
                        <Text style={styles.createButtonText}>Create</Text>
                      )}
                    </TouchableOpacity>
                  </View>
                </View>
              </ScrollView>
            </KeyboardAvoidingView>
          </TouchableOpacity>
        </TouchableOpacity>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#f3f4f6",
  },
  centered: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#f3f4f6",
    padding: 24,
  },
  header: {
    paddingHorizontal: 16,
    paddingTop: 60,
    paddingBottom: 16,
    backgroundColor: "#ffffff",
    borderBottomWidth: 1,
    borderBottomColor: "#e5e7eb",
  },
  headerRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  headerText: {
    flex: 1,
  },
  title: {
    fontSize: 28,
    fontWeight: "bold",
    color: "#111827",
  },
  subtitle: {
    fontSize: 14,
    color: "#6b7280",
    marginTop: 4,
  },
  addButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: "#3b82f6",
    alignItems: "center",
    justifyContent: "center",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  addButtonText: {
    fontSize: 28,
    color: "#ffffff",
    fontWeight: "300",
    lineHeight: 32,
  },
  list: {
    padding: 16,
  },
  card: {
    backgroundColor: "#ffffff",
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 2,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: "600",
    color: "#111827",
  },
  cardDescription: {
    fontSize: 14,
    color: "#6b7280",
    marginTop: 6,
  },
  cardDate: {
    fontSize: 12,
    color: "#9ca3af",
    marginTop: 8,
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: "#6b7280",
  },
  errorTitle: {
    fontSize: 24,
    fontWeight: "bold",
    color: "#dc2626",
    marginBottom: 8,
  },
  errorText: {
    fontSize: 14,
    color: "#6b7280",
    textAlign: "center",
    marginBottom: 16,
  },
  hint: {
    fontSize: 12,
    color: "#9ca3af",
    textAlign: "center",
    fontFamily: "monospace",
    marginBottom: 24,
  },
  emptyTitle: {
    fontSize: 24,
    fontWeight: "bold",
    color: "#111827",
    marginBottom: 8,
  },
  emptyText: {
    fontSize: 14,
    color: "#6b7280",
    textAlign: "center",
    marginBottom: 24,
  },
  retryButton: {
    backgroundColor: "#3b82f6",
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  retryButtonText: {
    color: "#ffffff",
    fontSize: 16,
    fontWeight: "600",
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0, 0, 0, 0.5)",
    justifyContent: "center",
    alignItems: "center",
    padding: 20,
  },
  modalTouchableContent: {
    width: "100%",
    maxWidth: 400,
  },
  keyboardAvoidingView: {
    width: "100%",
  },
  modalScrollContent: {
    flexGrow: 1,
    justifyContent: "center",
  },
  modalContent: {
    backgroundColor: "#ffffff",
    borderRadius: 16,
    padding: 24,
    width: "100%",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 5,
  },
  modalTitle: {
    fontSize: 24,
    fontWeight: "bold",
    color: "#111827",
    marginBottom: 20,
  },
  inputLabel: {
    fontSize: 14,
    fontWeight: "600",
    color: "#374151",
    marginBottom: 8,
    marginTop: 12,
  },
  input: {
    borderWidth: 1,
    borderColor: "#d1d5db",
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    color: "#111827",
    backgroundColor: "#ffffff",
  },
  textArea: {
    minHeight: 80,
    textAlignVertical: "top",
  },
  modalButtons: {
    flexDirection: "row",
    justifyContent: "flex-end",
    marginTop: 24,
    gap: 12,
  },
  modalButton: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
    minWidth: 100,
    alignItems: "center",
  },
  cancelButton: {
    backgroundColor: "#f3f4f6",
  },
  cancelButtonText: {
    color: "#374151",
    fontSize: 16,
    fontWeight: "600",
  },
  createButton: {
    backgroundColor: "#3b82f6",
  },
  createButtonText: {
    color: "#ffffff",
    fontSize: 16,
    fontWeight: "600",
  },
  disabledButton: {
    opacity: 0.6,
  },
});
