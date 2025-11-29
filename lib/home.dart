import 'package:flutter/material.dart';
import 'medication.dart';
import 'interaction.dart';
import 'notification.dart';
import 'addmed.dart';
import 'recurrence.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Medicine> meds = [];
  void addMedication(Medicine med) {
    setState(() => meds.add(med));
    final result = InteractionService.check(meds);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ $result"), backgroundColor: Colors.red,
            duration: const Duration(days: 1),action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ));
    }

    NotificationService.scheduleMedicine(medicine: med);
  }

  void deleteMedication(int i) {
    final medToDelete = meds[i];
    NotificationService.cancelAllReminders(medToDelete.id);
    setState(() => meds.removeAt(i));
  }
  String weekdayName(int day) {
    switch(day) {
      case 1: return "Mon";
      case 2: return "Tue";
      case 3: return "Wed";
      case 4: return "Thu";
      case 5: return "Fri";
      case 6: return "Sat";
      case 7: return "Sun";
      default: return "";
    }
  }

  String _getScheduleDescription(Medicine med) {
    final String timeString = med.times.map((t) => t.format(context)).join(', ');

    switch (med.recurrence) {
      case RecurrenceType.daily:
        return "Daily at $timeString";

      case RecurrenceType.dayOfWeek:
        final days = med.daysOfWeek!.map(weekdayName).join(', ');
        return "Weekly on $days at $timeString";

      case RecurrenceType.everyXDays:
        final interval = med.intervalDays ?? 1;
        return "Every $interval days at $timeString";

      case RecurrenceType.once:
        return "Once at $timeString";

      case RecurrenceType.monthly:
        return "Monthly at $timeString";

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Medications", style:TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddMedDialog(onAdd: addMedication),
        ),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/back.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child:SizedBox(
                  width: 350,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final result = InteractionService.check(meds);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result ?? "No interactions.Your List is Safe ✔"),
                          backgroundColor:
                          result == null ? Colors.blue : Colors.red,
                          duration: const Duration(seconds: 6),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search),
                    label: const Text("Check Interactions"
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Medication List
              Expanded(
                child: meds.isEmpty
                    ? const Center(
                  child: Text(
                    "No Medications Added.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: meds.length,
                  itemBuilder: (context, i) {
                    final med = meds[i];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.medication, color: Colors
                            .blue),
                        title: Text(
                          meds[i].name,
                          style: const TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Dose: ${med.dose}\n${_getScheduleDescription(
                              med)}",
                          style: const TextStyle(color: Colors.blue),

                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.blue),
                          onPressed: () => deleteMedication(i),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}



