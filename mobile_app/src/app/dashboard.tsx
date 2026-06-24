import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, RefreshControl } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import axios from 'axios';

const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://192.168.1.61:8000';

export default function DashboardScreen() {
  const { employeeStr } = useLocalSearchParams();
  const employee = employeeStr ? JSON.parse(employeeStr as string) : null;
  const [projects, setProjects] = useState([]);
  const [history, setHistory] = useState([]);
  const [refreshing, setRefreshing] = useState(false);

  const fetchData = async () => {
    if (!employee) return;
    try {
      const [projRes, histRes] = await Promise.all([
        axios.get(`${API_BASE_URL}/api/employee/${employee.employee_id}/projects`),
        axios.get(`${API_BASE_URL}/api/employee/${employee.employee_id}/history`)
      ]);
      setProjects(projRes.data.projects || []);
      setHistory(histRes.data.logs || []);
    } catch (error) {
      console.log(error);
    }
  };

  useEffect(() => {
    fetchData();
  }, [employee]);

  const onRefresh = async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
  };

  if (!employee) {
    return <View style={styles.container}><Text style={{color:'white'}}>Session expired. Please login again.</Text></View>;
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <View>
          <Text style={styles.greeting}>Welcome back,</Text>
          <Text style={styles.name}>{employee.name}</Text>
        </View>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{employee.name.charAt(0)}</Text>
        </View>
      </View>

      <ScrollView 
        contentContainerStyle={styles.scrollContent}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#8b5cf6" />}
      >
        <Text style={styles.sectionTitle}>My Projects</Text>
        {projects.length === 0 ? (
          <Text style={styles.emptyText}>No active projects</Text>
        ) : (
          projects.map((p: any) => (
            <TouchableOpacity 
              key={p.subject_id} 
              style={styles.card}
              onPress={() => router.push({ pathname: '/checkin', params: { employeeStr, subjectId: p.subject_id, subjectName: p.name } })}
            >
              <View style={styles.cardHeader}>
                <Text style={styles.cardTitle}>{p.name}</Text>
                <View style={styles.badge}><Text style={styles.badgeText}>{p.subject_code}</Text></View>
              </View>
              <Text style={styles.cardAction}>Tap to Check-in →</Text>
            </TouchableOpacity>
          ))
        )}

        <Text style={[styles.sectionTitle, { marginTop: 30 }]}>Recent Attendance</Text>
        {history.length === 0 ? (
          <Text style={styles.emptyText}>No attendance records</Text>
        ) : (
          history.slice(0, 5).map((log: any, idx) => {
            const date = new Date(log.timestamp).toLocaleDateString();
            const time = new Date(log.timestamp).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
            return (
              <View key={idx} style={styles.logItem}>
                <View>
                  <Text style={styles.logProject}>{log.subjects?.name || 'Project'}</Text>
                  <Text style={styles.logDate}>{date} at {time}</Text>
                </View>
                <View style={[styles.statusBadge, log.is_present ? styles.statusPresent : styles.statusAbsent]}>
                  <Text style={[styles.statusText, log.is_present ? styles.statusTextPresent : styles.statusTextAbsent]}>
                    {log.is_present ? 'Present' : 'Absent'}
                  </Text>
                </View>
              </View>
            );
          })
        )}
      </ScrollView>

      <TouchableOpacity style={styles.logoutBtn} onPress={() => router.replace('/')}>
        <Text style={styles.logoutText}>Sign Out</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#050505', paddingTop: 60 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 24, marginBottom: 30 },
  greeting: { color: '#a1a1aa', fontSize: 16 },
  name: { color: '#fff', fontSize: 28, fontWeight: '800' },
  avatar: { width: 50, height: 50, borderRadius: 25, backgroundColor: '#8b5cf6', justifyContent: 'center', alignItems: 'center' },
  avatarText: { color: '#fff', fontSize: 20, fontWeight: 'bold' },
  scrollContent: { paddingHorizontal: 24, paddingBottom: 100 },
  sectionTitle: { color: '#fff', fontSize: 20, fontWeight: '700', marginBottom: 16 },
  card: { backgroundColor: 'rgba(255,255,255,0.05)', borderWidth: 1, borderColor: 'rgba(255,255,255,0.1)', borderRadius: 20, padding: 20, marginBottom: 16 },
  cardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 },
  cardTitle: { color: '#fff', fontSize: 18, fontWeight: '600' },
  badge: { backgroundColor: 'rgba(139, 92, 246, 0.2)', paddingHorizontal: 10, paddingVertical: 4, borderRadius: 100 },
  badgeText: { color: '#c084fc', fontSize: 12, fontWeight: 'bold' },
  cardAction: { color: '#8b5cf6', fontSize: 14, fontWeight: '600' },
  logItem: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: 'rgba(255,255,255,0.02)', padding: 16, borderRadius: 16, marginBottom: 10 },
  logProject: { color: '#fff', fontSize: 16, fontWeight: '600' },
  logDate: { color: '#a1a1aa', fontSize: 13, marginTop: 4 },
  statusBadge: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 100 },
  statusPresent: { backgroundColor: 'rgba(34, 197, 94, 0.15)' },
  statusAbsent: { backgroundColor: 'rgba(239, 68, 68, 0.15)' },
  statusText: { fontSize: 12, fontWeight: '700' },
  statusTextPresent: { color: '#4ade80' },
  statusTextAbsent: { color: '#f87171' },
  emptyText: { color: '#a1a1aa', fontStyle: 'italic', marginBottom: 20 },
  logoutBtn: { position: 'absolute', bottom: 40, left: 24, right: 24, backgroundColor: 'rgba(255,255,255,0.1)', paddingVertical: 16, borderRadius: 100, alignItems: 'center' },
  logoutText: { color: '#fff', fontSize: 16, fontWeight: '600' }
});
