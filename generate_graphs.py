import matplotlib.pyplot as plt

# ===== Graph 1: Response time vs request rate, for 1/2/3 replicas =====
rates = [10, 25, 50, 100, 200]
resp_1 = [593.552, 761.389, 1168.029, 2318.205, 5695.481]
resp_2 = [617.448, 844.594, 1197.149, 2771.974, 16217.528]
resp_3 = [679.697, 961.690, 1776.391, 1221.899, 1225.562]

plt.figure(figsize=(8,5))
plt.plot(rates, resp_1, marker='o', label='1 replica')
plt.plot(rates, resp_2, marker='o', label='2 replicas')
plt.plot(rates, resp_3, marker='o', label='3 replicas')
plt.xlabel('Request rate (req/s)')
plt.ylabel('Average response time (ms)')
plt.title('Graph 1: Response Time vs Request Rate')
plt.legend()
plt.grid(True)
plt.savefig('graph1_response_time.png', dpi=150, bbox_inches='tight')
plt.close()

# ===== Graph 2: CPU utilization over time per pod, 100 req/s, 3 replicas =====
timestamps = [1795596608, 1795596623, 1795596639, 1795596655]
t0 = timestamps[0]
rel_time = [(t - t0) for t in timestamps]

pod1_cpu = [13, 13, 42, 42]  # fkj5z
pod2_cpu = [13, 13, 42, 42]  # qn4q8
pod3_cpu = [13, 13, 40, 40]  # wt2mk

plt.figure(figsize=(8,5))
plt.plot(rel_time, pod1_cpu, marker='o', linestyle='-', linewidth=3, label='emi-web pod 1 (fkj5z)')
plt.plot(rel_time, pod2_cpu, marker='x', linestyle='--', linewidth=2, label='emi-web pod 2 (qn4q8)')
plt.plot(rel_time, pod3_cpu, marker='s', linestyle=':', linewidth=2, label='emi-web pod 3 (wt2mk)')
plt.xlabel('Time (seconds)')
plt.ylabel('CPU usage (millicores)')
plt.title('Graph 2: CPU Utilization per Pod (100 req/s, 3 replicas)')
plt.legend()
plt.grid(True)
plt.savefig('graph2_cpu_utilization.png', dpi=150, bbox_inches='tight')
plt.close()

# ===== Graph 3: Request rate, CPU%, replica count during autoscaling test =====
hpa_timestamps = [1795601114,1795601129,1795601144,1795601160,1795601175,1795601191,1795601206,
                   1795601222,1795601238,1795601254,1795601270,1795601288,1795601304,1795601320,
                   1795601335,1795601351,1795601367,1795601383,1795601400,1795601425,1795601453,
                   1795601473,1795601496,1795601531,1795601549,1795601564,1795601579,1795601595,
                   1795601610,1795601626,1795601641,1795601657,1795601673,1795601688,1795601704]
hpa_replicas = [1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,4,4,4,1,1,1,1,1,1,1,1,2,2,2,2,1]

t0_hpa = hpa_timestamps[0]
hpa_rel_time = [(t - t0_hpa) for t in hpa_timestamps]

# Request rate phases: 10 req/s (0-120s), 100 req/s (120-420s), 10 req/s (420-600s)
phase_times = [0, 120, 120, 420, 420, 600]
phase_rates = [10, 10, 100, 100, 10, 10]

fig, ax1 = plt.subplots(figsize=(10,6))

ax1.plot(hpa_rel_time, hpa_replicas, marker='o', color='tab:blue', label='Replica count')
ax1.set_xlabel('Time (seconds)')
ax1.set_ylabel('Replica count', color='tab:blue')
ax1.tick_params(axis='y', labelcolor='tab:blue')

ax2 = ax1.twinx()
ax2.plot(phase_times, phase_rates, color='tab:red', linestyle='--', label='Target request rate')
ax2.set_ylabel('Request rate (req/s)', color='tab:red')
ax2.tick_params(axis='y', labelcolor='tab:red')

plt.title('Graph 3: Autoscaling Test — Request Rate & Replica Count Over Time')
fig.tight_layout()
plt.savefig('graph3_autoscaling.png', dpi=150, bbox_inches='tight')
plt.close()

print("All 3 graphs generated successfully!")