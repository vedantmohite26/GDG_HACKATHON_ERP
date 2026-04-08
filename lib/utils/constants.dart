// App-wide constants and configuration

import 'package:flutter/material.dart';

// App Information
class AppInfo {
  static const String appName = 'UniConnect';
  static const String version = '1.0.0';
}

// Firestore Collection Names
class Collections {
  static const String users = 'users';
  static const String studentProfiles = 'student_profiles';
  static const String scholarships = 'scholarships';
  static const String applications = 'applications';
  static const String grievances = 'grievances';
  static const String documentsMeta = 'documents_meta';
  static const String academicInfo = 'academic_info';
  static const String auditLogs = 'audit_logs';
  static const String notices = 'notices';
}

// User Roles
class UserRole {
  static const String student = 'student';
  static const String faculty = 'faculty'; // Operational staff
  static const String admin = 'admin'; // Alias for faculty (backwards compat)
  static const String committee = 'committee'; // Strategic oversight
}

// Application Status
class ApplicationStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

// Grievance Status
class GrievanceStatus {
  static const String pending = 'pending';
  static const String assigned = 'assigned';
  static const String inProgress = 'in-progress';
  static const String resolved = 'resolved';
}

// Grievance Categories
class GrievanceCategory {
  static const String academic = 'Academic';
  static const String financial = 'Financial';
  static const String hostel = 'Hostel';
  static const String infrastructure = 'Infrastructure';
  static const String discrimination = 'Discrimination';
  static const String other = 'Other';

  static const List<String> all = [
    academic,
    financial,
    hostel,
    infrastructure,
    discrimination,
    other,
  ];
}

// Student Categories
class StudentCategory {
  static const String general = 'General';
  static const String obc = 'OBC';
  static const String sc = 'SC';
  static const String st = 'ST';
  static const String ews = 'EWS';

  static const List<String> all = [general, obc, sc, st, ews];
}

// Courses
class Courses {
  static const String compEng = 'Computer Engineering';
  static const String it = 'Information Technology';
  static const String mechEng = 'Mechanical Engineering';
  static const String civilEng = 'Civil Engineering';
  static const String elecEng = 'Electrical Engineering';
  static const String entc = 'Electronics & Telecom';
  static const String aids = 'AI & DS';

  static const List<String> all = [
    compEng,
    it,
    mechEng,
    civilEng,
    elecEng,
    entc,
    aids,
  ];
}

// Blood Groups
class BloodGroup {
  static const String aPlus = 'A+';
  static const String aMinus = 'A-';
  static const String bPlus = 'B+';
  static const String bMinus = 'B-';
  static const String oPlus = 'O+';
  static const String oMinus = 'O-';
  static const String abPlus = 'AB+';
  static const String abMinus = 'AB-';

  static const List<String> all = [
    aPlus,
    aMinus,
    bPlus,
    bMinus,
    oPlus,
    oMinus,
    abPlus,
    abMinus,
  ];
}

// Academic Shifts
class AcademicShift {
  static const String first = 'FIRST';
  static const String second = 'SECOND';

  static const List<String> all = [first, second];
}

// Subject Model
class SubjectModel {
  final String name;
  final int credits;
  const SubjectModel(this.name, this.credits);
}

class BranchSubjects {
  static const Map<String, Map<String, Map<String, List<SubjectModel>>>>
  data = {
    Courses.compEng: {
      '1st Year': {
        'Semester 1': [
          SubjectModel('Engineering Mathematics-I', 4),
          SubjectModel('Physics', 4),
          SubjectModel('Systems in Mech. Eng.', 3),
          SubjectModel('BEE', 3),
          SubjectModel('Engineering Mechanics', 3),
        ],
        'Semester 2': [
          SubjectModel('Engineering Mathematics-II', 4),
          SubjectModel('Chemistry', 4),
          SubjectModel('PPS', 3),
          SubjectModel('Basic Electronics', 3),
          SubjectModel('Eng. Graphics', 3),
        ],
      },
      '2nd Year': {
        'Semester 3': [
          SubjectModel('Discrete Mathematics', 4),
          SubjectModel('Data Structures', 3),
          SubjectModel('COA', 3),
          SubjectModel('Digital Logic', 3),
          SubjectModel('OOP with C++', 3),
        ],
        'Semester 4': [
          SubjectModel('Eng. Mathematics-III', 4),
          SubjectModel('Microprocessors', 3),
          SubjectModel('Theory of Computation', 3),
          SubjectModel('Computer Graphics', 3),
          SubjectModel('Management Info. Systems', 3),
        ],
      },
      '3rd Year': {
        'Semester 5': [
          SubjectModel('Database Management', 4),
          SubjectModel('Computer Networks', 3),
          SubjectModel('Software Engineering', 3),
          SubjectModel('TOC', 3),
          SubjectModel('IPR', 2),
        ],
        'Semester 6': [
          SubjectModel('Data Science', 4),
          SubjectModel('Cloud Computing', 3),
          SubjectModel('Embedded Systems', 3),
          SubjectModel('Machine Learning', 3),
          SubjectModel('Web Technology', 3),
        ],
      },
      '4th Year': {
        'Semester 7': [
          SubjectModel('Design & Analysis of Algo', 4),
          SubjectModel('Big Data Analytics', 3),
          SubjectModel('Mobile Computing', 3),
          SubjectModel('Cyber Security', 3),
          SubjectModel('Project I', 4),
        ],
        'Semester 8': [
          SubjectModel('Distributed Systems', 4),
          SubjectModel('Deep Learning', 3),
          SubjectModel('HCI', 3),
          SubjectModel('Elective IV', 3),
          SubjectModel('Project II', 6),
        ],
      },
    },
    Courses.it: {
      '1st Year': {
        'Semester 1': [
          SubjectModel('Engineering Mathematics-I', 4),
          SubjectModel('Physics', 4),
          SubjectModel('Systems in Mech. Eng.', 3),
          SubjectModel('BEE', 3),
          SubjectModel('Engineering Mechanics', 3),
        ],
        'Semester 2': [
          SubjectModel('Engineering Mathematics-II', 4),
          SubjectModel('Chemistry', 4),
          SubjectModel('PPS', 4),
          SubjectModel('Basic Electronics', 3),
          SubjectModel('Eng. Graphics', 3),
        ],
      },
      '2nd Year': {
        'Semester 3': [
          SubjectModel('Discrete Mathematics', 4),
          SubjectModel('Data Structures', 4),
          SubjectModel('COA', 3),
          SubjectModel('Digital Logic', 3),
          SubjectModel('Java Programming', 4),
        ],
        'Semester 4': [
          SubjectModel('Eng. Mathematics-III', 4),
          SubjectModel('Microprocessors', 3),
          SubjectModel('Theory of Computation', 3),
          SubjectModel('Computer Graphics', 3),
          SubjectModel('MIS', 3),
        ],
      },
      '3rd Year': {
        'Semester 5': [
          SubjectModel('Web Technology', 4),
          SubjectModel('OS', 4),
          SubjectModel('Computer Networks', 3),
          SubjectModel('HCI', 3),
          SubjectModel('Software Engineering', 3),
        ],
        'Semester 6': [
          SubjectModel('Data Mining', 4),
          SubjectModel('Cloud Computing', 4),
          SubjectModel('Network Security', 3),
          SubjectModel('Mobile App Development', 4),
          SubjectModel('E-Commerce', 3),
        ],
      },
      '4th Year': {
        'Semester 7': [
          SubjectModel('Information Security', 4),
          SubjectModel('Smart Cities', 3),
          SubjectModel('Data Science', 4),
          SubjectModel('Project Phase I', 4),
          SubjectModel('Machine Learning', 4),
        ],
        'Semester 8': [
          SubjectModel('Block Chain', 4),
          SubjectModel('Social Media Analytics', 3),
          SubjectModel('Project Phase II', 6),
          SubjectModel('Optimization Techniques', 3),
          SubjectModel('Green IT', 3),
        ],
      },
    },
    Courses.aids: {
      '1st Year': {
        'Semester 1': [
          SubjectModel('Mathematics-I', 4),
          SubjectModel('Physics', 4),
          SubjectModel('Systems Engineering', 3),
          SubjectModel('BEE', 3),
          SubjectModel('Mechanics', 3),
        ],
        'Semester 2': [
          SubjectModel('Mathematics-II', 4),
          SubjectModel('Chemistry', 4),
          SubjectModel('Python', 4),
          SubjectModel('Electronics', 3),
          SubjectModel('Graphics', 3),
        ],
      },
      '2nd Year': {
        'Semester 3': [
          SubjectModel('Statistics', 3),
          SubjectModel('Data Structures', 4),
          SubjectModel('Python for DS', 4),
          SubjectModel('Linear Algebra', 3),
          SubjectModel('OOP', 4),
        ],
        'Semester 4': [
          SubjectModel('Mathematics-III', 4),
          SubjectModel('Database Mgt.', 3),
          SubjectModel('Algo Design', 3),
          SubjectModel('Computer Org.', 3),
          SubjectModel('Ethical Hacking', 3),
        ],
      },
      '3rd Year': {
        'Semester 5': [
          SubjectModel('AI Fundamentals', 4),
          SubjectModel('Data Mining', 3),
          SubjectModel('Machine Learning', 4),
          SubjectModel('Big Data', 4),
          SubjectModel('Neural Networks', 3),
        ],
        'Semester 6': [
          SubjectModel('Natural Lang Process', 4),
          SubjectModel('Reinforcement Learning', 3),
          SubjectModel('Cognitive Computing', 4),
          SubjectModel('Web AI', 4),
          SubjectModel('Bioinformatics', 3),
        ],
      },
      '4th Year': {
        'Semester 7': [
          SubjectModel('Deep Learning', 4),
          SubjectModel('NLP Advanced', 3),
          SubjectModel('Computer Vision', 4),
          SubjectModel('Project Part I', 4),
          SubjectModel('Robotics', 3),
        ],
        'Semester 8': [
          SubjectModel('Generative AI', 4),
          SubjectModel('Edge AI', 3),
          SubjectModel('Computer Graphics', 4),
          SubjectModel('Project Final', 6),
          SubjectModel('Autonomous Vehicles', 3),
        ],
      },
    },
    Courses.mechEng: {
      '1st Year': {
        'Semester 1': [
          SubjectModel('Eng. Mathematics-I', 4),
          SubjectModel('Eng. Physics', 4),
          SubjectModel('Systems in Mech. Eng.', 3),
          SubjectModel('BEE', 3),
          SubjectModel('Eng. Mechanics', 3),
        ],
        'Semester 2': [
          SubjectModel('Eng. Mathematics-II', 4),
          SubjectModel('Eng. Chemistry', 4),
          SubjectModel('PPS', 3),
          SubjectModel('Basic Electronics', 3),
          SubjectModel('Eng. Graphics', 3),
        ],
      },
      '2nd Year': {
        'Semester 3': [
          SubjectModel('Eng. Mathematics-III', 4),
          SubjectModel('Thermodynamics', 3),
          SubjectModel('Material Science', 3),
          SubjectModel('Solid Mechanics', 4),
          SubjectModel('Manufacturing Proc.', 3),
        ],
        'Semester 4': [
          SubjectModel('Fluid Mechanics', 4),
          SubjectModel('Theory of Machines-I', 3),
          SubjectModel('Eng. Metallurgy', 3),
          SubjectModel('Applied Thermo.', 3),
          SubjectModel('Electrical Machines', 3),
        ],
      },
      '3rd Year': {
        'Semester 5': [
          SubjectModel('Design of Machine Elements', 4),
          SubjectModel('Heat Transfer', 4),
          SubjectModel('Theory of Machines-II', 3),
          SubjectModel('Metrology & Quality', 3),
          SubjectModel('Value Education', 2),
        ],
        'Semester 6': [
          SubjectModel('Numerical Methods', 4),
          SubjectModel('Mechatronics', 4),
          SubjectModel('Turbo Machines', 3),
          SubjectModel('Computer Aided Design', 3),
          SubjectModel('Refrig. & Air Cond.', 3),
        ],
      },
      '4th Year': {
        'Semester 7': [
          SubjectModel('Heating, Vent. & AC', 4),
          SubjectModel('Dynamics of Machinery', 3),
          SubjectModel('Project Phase I', 4),
          SubjectModel('Industrial Engineering', 3),
          SubjectModel('Automobile Engineering', 3),
        ],
        'Semester 8': [
          SubjectModel('Energy Engineering', 4),
          SubjectModel('Mechanical Vibrations', 3),
          SubjectModel('Project Phase II', 6),
          SubjectModel('Robotics', 3),
          SubjectModel('Operations Research', 3),
        ],
      },
    },
    Courses.civilEng: {
      '1st Year': {
        'Semester 1': [
          SubjectModel('Mathematics-I', 4),
          SubjectModel('Physics', 4),
          SubjectModel('Systems in Mech. Eng.', 3),
          SubjectModel('BEE', 3),
          SubjectModel('Mechanics', 3),
        ],
        'Semester 2': [
          SubjectModel('Mathematics-II', 4),
          SubjectModel('Chemistry', 4),
          SubjectModel('PPS', 3),
          SubjectModel('Basic Electronics', 3),
          SubjectModel('Eng. Graphics', 3),
        ],
      },
      '2nd Year': {
        'Semester 3': [
          SubjectModel('Mathematics-III', 4),
          SubjectModel('Surveying', 3),
          SubjectModel('Strength of Materials', 4),
          SubjectModel('Fluid Mechanics I', 3),
          SubjectModel('Eng. Geology', 3),
        ],
        'Semester 4': [
          SubjectModel('Geotechnical Eng. I', 4),
          SubjectModel('Structural Analysis-I', 3),
          SubjectModel('Concrete Technology', 3),
          SubjectModel('Fluid Mechanics II', 3),
          SubjectModel('Building Planning', 3),
        ],
      },
      '3rd Year': {
        'Semester 5': [
          SubjectModel('Hydrology & Water Res.', 4),
          SubjectModel('Infrastructure Eng.', 3),
          SubjectModel('Structural Design-I', 4),
          SubjectModel('Structural Analysis-II', 3),
          SubjectModel('Environmental Eng. I', 3),
        ],
        'Semester 6': [
          SubjectModel('Foundations Eng.', 4),
          SubjectModel('Project Management', 4),
          SubjectModel('Structural Design-II', 4),
          SubjectModel('Environmental Eng. II', 3),
          SubjectModel('Transportation Eng. I', 3),
        ],
      },
      '4th Year': {
        'Semester 7': [
          SubjectModel('Environmental Eng. III', 4),
          SubjectModel('Transportation Eng. II', 3),
          SubjectModel('Project Phase I', 4),
          SubjectModel('Dam Engineering', 3),
          SubjectModel('Quantity Surveying', 3),
        ],
        'Semester 8': [
          SubjectModel('Construction Mgt.', 4),
          SubjectModel('Earthquake Engineering', 3),
          SubjectModel('Project Phase II', 6),
          SubjectModel('Tundel Eng.', 3),
          SubjectModel('Hydropower Eng.', 3),
        ],
      },
    },
    Courses.elecEng: {
      '1st Year': {
        'Semester 1': [
          SubjectModel('Eng. Mathematics-I', 4),
          SubjectModel('Eng. Physics', 4),
          SubjectModel('Systems in Mech. Eng.', 3),
          SubjectModel('BEE', 3),
          SubjectModel('Eng. Mechanics', 3),
        ],
        'Semester 2': [
          SubjectModel('Eng. Mathematics-II', 4),
          SubjectModel('Eng. Chemistry', 4),
          SubjectModel('PPS', 3),
          SubjectModel('Basic Electronics', 3),
          SubjectModel('Eng. Graphics', 3),
        ],
      },
      '2nd Year': {
        'Semester 3': [
          SubjectModel('Mathematics-III', 4),
          SubjectModel('Power Generation Tech.', 3),
          SubjectModel('Electrical Machines-I', 4),
          SubjectModel('Network Analysis', 3),
          SubjectModel('Analog Electronics', 3),
        ],
        'Semester 4': [
          SubjectModel('Power Systems-I', 4),
          SubjectModel('Electrical Machines-II', 3),
          SubjectModel('Measurements & Instr.', 3),
          SubjectModel('Digital Electronics', 3),
          SubjectModel('Electromagnetics', 3),
        ],
      },
      '3rd Year': {
        'Semester 5': [
          SubjectModel('Power Systems-II', 4),
          SubjectModel('Control Systems', 4),
          SubjectModel('Power Electronics', 3),
          SubjectModel('Microcontrollers', 3),
          SubjectModel('Signal Processing', 3),
        ],
        'Semester 6': [
          SubjectModel('Switchgear & Protection', 4),
          SubjectModel('High Voltage Eng.', 4),
          SubjectModel('Electric Drives', 4),
          SubjectModel('Smart Grids', 3),
          SubjectModel('PLC & SCADA', 3),
        ],
      },
      '4th Year': {
        'Semester 7': [
          SubjectModel('Power Quality', 4),
          SubjectModel('Renewable Energy', 3),
          SubjectModel('Project Phase I', 4),
          SubjectModel('EHVAC', 3),
          SubjectModel('Electric Vehicles', 3),
        ],
        'Semester 8': [
          SubjectModel('HVDC Systems', 4),
          SubjectModel('Smart Systems', 3),
          SubjectModel('Project Phase II', 6),
          SubjectModel('Robotics & Automation', 3),
          SubjectModel('Illumination Eng.', 3),
        ],
      },
    },
    Courses.entc: {
      '1st Year': {
        'Semester 1': [
          SubjectModel('Eng. Mathematics-I', 4),
          SubjectModel('Eng. Physics', 4),
          SubjectModel('Systems in Mech. Eng.', 3),
          SubjectModel('BEE', 3),
          SubjectModel('Eng. Mechanics', 3),
        ],
        'Semester 2': [
          SubjectModel('Eng. Mathematics-II', 4),
          SubjectModel('Eng. Chemistry', 4),
          SubjectModel('PPS', 3),
          SubjectModel('Basic Electronics', 3),
          SubjectModel('Eng. Graphics', 3),
        ],
      },
      '2nd Year': {
        'Semester 3': [
          SubjectModel('Mathematics-III', 4),
          SubjectModel('Electronic Circuits', 3),
          SubjectModel('Digital Circuits', 4),
          SubjectModel('Network Theory', 3),
          SubjectModel('Data Structures', 3),
        ],
        'Semester 4': [
          SubjectModel('Signals & Systems', 4),
          SubjectModel('Microprocessors', 3),
          SubjectModel('Control Systems', 3),
          SubjectModel('Principles of Comm.', 3),
          SubjectModel('Project Mgt.', 3),
        ],
      },
      '3rd Year': {
        'Semester 5': [
          SubjectModel('Digital Comm.', 4),
          SubjectModel('Microcontrollers', 4),
          SubjectModel('VLSI Design', 3),
          SubjectModel('Antenna & Propagation', 3),
          SubjectModel('Signal Processing', 3),
        ],
        'Semester 6': [
          SubjectModel('Mobile Communication', 4),
          SubjectModel('Embedded Systems', 4),
          SubjectModel('Computer Networks', 4),
          SubjectModel('Microwave Eng.', 3),
          SubjectModel('Information Theory', 3),
        ],
      },
      '4th Year': {
        'Semester 7': [
          SubjectModel('Optical Fiber Comm.', 4),
          SubjectModel('RF Design', 3),
          SubjectModel('Project Phase I', 4),
          SubjectModel('Deep Learning', 3),
          SubjectModel('IoT & Applications', 3),
        ],
        'Semester 8': [
          SubjectModel('Wireless Networks', 4),
          SubjectModel('Satellite Comm.', 3),
          SubjectModel('Project Phase II', 6),
          SubjectModel('Robotics', 3),
          SubjectModel('Cloud Computing', 3),
        ],
      },
    },
    // Default fallback for others
    'default': {
      '1st Year': {
        'Semester 1': [SubjectModel('Sub 101', 3), SubjectModel('Sub 102', 3)],
        'Semester 2': [SubjectModel('Sub 103', 3), SubjectModel('Sub 104', 3)],
      },
      '2nd Year': {
        'Semester 3': [SubjectModel('Sub 201', 3), SubjectModel('Sub 202', 3)],
        'Semester 4': [SubjectModel('Sub 203', 3), SubjectModel('Sub 204', 3)],
      },
      '3rd Year': {
        'Semester 5': [SubjectModel('Sub 301', 3), SubjectModel('Sub 302', 3)],
        'Semester 6': [SubjectModel('Sub 303', 3), SubjectModel('Sub 304', 3)],
      },
      '4th Year': {
        'Semester 7': [SubjectModel('Sub 401', 3), SubjectModel('Sub 402', 3)],
        'Semester 8': [SubjectModel('Sub 403', 3), SubjectModel('Sub 404', 3)],
      },
    },
  };

  static List<SubjectModel> getSubjects(
    String branch,
    String year,
    String semester,
  ) {
    if (data.containsKey(branch) &&
        data[branch]!.containsKey(year) &&
        data[branch]![year]!.containsKey(semester)) {
      return data[branch]![year]![semester]!;
    }
    return data['default']?[year]?[semester] ?? [];
  }
}

// Academic Event Types
class AcademicEventType {
  static const String exam = 'exam';
  static const String holiday = 'holiday';
  static const String result = 'result';
  static const String other = 'other';
}

// App Colors
class AppColors {
  static const Color primary = Color(0xFF6200EE);
  static const Color primaryDark = Color(0xFF3700B3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

// SLA (Service Level Agreement) Times in hours
class SLAConfig {
  static const int academicGrievance = 48; // 2 days
  static const int financialGrievance = 72; // 3 days
  static const int hostelGrievance = 24; // 1 day
  static const int infrastructureGrievance = 72; // 3 days
  static const int discriminationGrievance = 12; // 12 hours (high priority)
  static const int otherGrievance = 96; // 4 days

  static int getSLAHours(String category) {
    switch (category) {
      case GrievanceCategory.academic:
        return academicGrievance;
      case GrievanceCategory.financial:
        return financialGrievance;
      case GrievanceCategory.hostel:
        return hostelGrievance;
      case GrievanceCategory.infrastructure:
        return infrastructureGrievance;
      case GrievanceCategory.discrimination:
        return discriminationGrievance;
      default:
        return otherGrievance;
    }
  }
}

// File Upload Limits (FREE tier compliance)
class FileUploadLimits {
  static const int maxFileSizeInBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
}

// Notification Topics
class NotificationTopics {
  static const String allStudents = 'all_students';
  static const String allAdmins = 'all_admins';
  static const String allCommittee = 'all_committee';
  static const String scholarshipDeadlines = 'scholarship_deadlines';
  static const String grievanceUpdates = 'grievance_updates';
}
