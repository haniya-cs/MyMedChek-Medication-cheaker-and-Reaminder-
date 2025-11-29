class InteractionService {
  static final Map<String, List<String>> interactions = {
    "Ibuprofen": ["Aspirin", "Warfarin", "Prednisone"],
    "Aspirin": ["Ibuprofen", "Warfarin", "Clopidogrel"],
    "Paracetamol": ["Warfarin"],
    "Amoxicillin": ["Warfarin", "Methotrexate"],
    "Prednisone": ["Ibuprofen", "Ketorolac"],
    "Clopidogrel": ["Aspirin", "Omeprazole"],
    "Omeprazole": ["Clopidogrel"],
    "Metformin": ["Alcohol"],
    "Alcohol": ["Metformin", "Diazepam"],
    "Diazepam": ["Alcohol"],
    "Cetirizine": [],
  };

  static String? check(List meds) {
    for (var m1 in meds) {
      for (var m2 in meds) {
        if (m1 != m2 &&
            (interactions[m1.name]?.contains(m2.name) ?? false)) {
          return "⚠️ Interaction found between ${m1.name} and ${m2.name}."
              "Please revise with your doctor or check with a nearby pharmacy.";
        }
      }
    }
    return null;
  }
}
