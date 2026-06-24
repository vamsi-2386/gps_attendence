import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ActivityIndicator, Alert } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import * as Location from 'expo-location';
import axios from 'axios';

const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://192.168.1.61:8000';

export default function CheckinScreen() {
  const { employeeStr, subjectId, subjectName } = useLocalSearchParams();
  const employee = employeeStr ? JSON.parse(employeeStr as string) : null;
  const [loading, setLoading] = useState(false);
  const [location, setLocation] = useState<Location.LocationObject | null>(null);

  useEffect(() => {
    (async () => {
      let { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission Denied', 'Permission to access location was denied');
        return;
      }
      let loc = await Location.getCurrentPositionAsync({});
      setLocation(loc);
    })();
  }, []);

  const handleCheckin = async () => {
    if (!location || !employee) return;
    
    setLoading(true);
    try {
      const payload = {
        employee_id: employee.employee_id,
        subject_id: parseInt(subjectId as string),
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
        status_text: "Checked in via Mobile",
        is_present: true
      };

      const response = await axios.post(`${API_BASE_URL}/api/employee/checkin`, payload);
      
      if (response.data.status === 'success') {
        Alert.alert('Success', 'Checked in successfully!');
        router.back();
      }
    } catch (error: any) {
      console.log(error);
      Alert.alert('Error', error.response?.data?.detail || error.message || 'Failed to check in');
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.backBtn} onPress={() => router.back()}>
          <Text style={styles.backText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.title}>Project Check-in</Text>
      </View>

      <View style={styles.content}>
        <View style={styles.card}>
          <Text style={styles.label}>Project</Text>
          <Text style={styles.value}>{subjectName}</Text>
          
          <View style={styles.divider} />
          
          <Text style={styles.label}>Location Status</Text>
          {location ? (
            <Text style={styles.valueGps}>
              Lat: {location.coords.latitude.toFixed(4)}{'\n'}
              Lng: {location.coords.longitude.toFixed(4)}
            </Text>
          ) : (
            <ActivityIndicator color="#8b5cf6" />
          )}
        </View>

        <TouchableOpacity 
          style={[styles.checkinBtn, (!location || loading) && styles.disabledBtn]} 
          onPress={handleCheckin}
          disabled={!location || loading}
        >
          {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.checkinText}>Confirm GPS Check-in</Text>}
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#050505', paddingTop: 60 },
  header: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 24, marginBottom: 40 },
  backBtn: { paddingVertical: 8, paddingRight: 16 },
  backText: { color: '#8b5cf6', fontSize: 16, fontWeight: '600' },
  title: { color: '#fff', fontSize: 24, fontWeight: '800', marginLeft: 'auto', marginRight: 'auto', transform: [{translateX: -20}] },
  content: { paddingHorizontal: 24, flex: 1 },
  card: { backgroundColor: 'rgba(255,255,255,0.05)', borderRadius: 24, padding: 30, borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)' },
  label: { color: '#a1a1aa', fontSize: 14, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 1 },
  value: { color: '#fff', fontSize: 22, fontWeight: '700' },
  valueGps: { color: '#4ade80', fontSize: 16, fontWeight: '600', lineHeight: 24 },
  divider: { height: 1, backgroundColor: 'rgba(255,255,255,0.1)', marginVertical: 24 },
  checkinBtn: { backgroundColor: '#8b5cf6', paddingVertical: 18, borderRadius: 100, alignItems: 'center', marginTop: 'auto', marginBottom: 60, shadowColor: '#8b5cf6', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.4, shadowRadius: 15 },
  disabledBtn: { opacity: 0.5 },
  checkinText: { color: '#fff', fontSize: 18, fontWeight: '700' }
});
