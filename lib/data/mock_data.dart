import '../models/plant.dart';
import '../models/diagnosis.dart';

// Plantas del proyecto
final List<Plant> mockPlants = [];

// Actividades diarias
final Map<String, Map<String, dynamic>> mockActivities = {
  'riego': {
    'title': 'Regar plantas',
    'icon': '💧',
    'color': 0xFF4CAF50,
    'description': 'Regar los cultivos según su necesidad',
  },
  'fertilizacion': {
    'title': 'Fertilizar cultivos',
    'icon': '🌱',
    'color': 0xFF8BC34A,
    'description': 'Aplicar abono orgánico a las plantas',
  },
  'cosecha': {
    'title': 'Cosechar',
    'icon': '🧺',
    'color': 0xFFFF9800,
    'description': 'Recolectar frutos y verduras maduras',
  },
  'poda': {
    'title': 'Podar hojas',
    'icon': '✂️',
    'color': 0xFF795548,
    'description': 'Eliminar hojas secas o dañadas',
  },
  'monitoreo': {
    'title': 'Monitorear plagas',
    'icon': '🔍',
    'color': 0xFFF44336,
    'description': 'Revisar signos de plagas o enfermedades',
  },
};

// Diagnósticos de ejemplo para las plantas del proyecto
final List<Diagnosis> mockDiagnoses = [];

// Consejos y tratamientos
final Map<String, List<Map<String, dynamic>>> mockTreatments = {
  'Riego': [
    {
      'title': 'Riego eficiente',
      'description': 'Aprende a regar tus cultivos correctamente',
      'icon': '💧',
      'tips': [
        'Riega temprano en la mañana',
        'Usa riego por goteo',
        'Verifica la humedad del suelo',
        'Evita mojar las hojas',
      ],
    },
    {
      'title': 'Sistemas de riego',
      'description': 'Diferentes métodos para optimizar el agua',
      'icon': '🚿',
      'tips': [
        'Riego por goteo para cultivos en hilera',
        'Microaspersión para hortalizas',
        'Mulching para conservar humedad',
      ],
    },
  ],
  'Fertilización': [
    {
      'title': 'Abonos orgánicos',
      'description': 'Nutrientes naturales para tus cultivos',
      'icon': '🌱',
      'tips': [
        'Usa compost maduro',
        'Aplica humus de lombriz',
        'Prepara té de compost',
        'Incorpora estiércol compostado',
      ],
    },
  ],
  'Control de plagas': [
    {
      'title': 'Manejo integrado',
      'description': 'Control natural de plagas',
      'icon': '🐛',
      'tips': [
        'Monitorea tus cultivos',
        'Usa trampas naturales',
        'Fomenta insectos benéficos',
        'Rota cultivos',
      ],
    },
  ],
  'Cosecha': [
    {
      'title': 'Cuándo cosechar',
      'description': 'Identifica el momento ideal',
      'icon': '🧺',
      'tips': [
        'Cosecha temprano',
        'Usa herramientas limpias',
        'Maneja con cuidado',
        'Almacena correctamente',
      ],
    },
  ],
  'Prevención': [
    {
      'title': 'Buenas prácticas',
      'description': 'Prevén enfermedades en tus cultivos',
      'icon': '🛡️',
      'tips': [
        'Limpia herramientas regularmente',
        'Elimina plantas enfermas',
        'Mantén buena ventilación',
        'Usa semillas certificadas',
      ],
    },
  ],
};