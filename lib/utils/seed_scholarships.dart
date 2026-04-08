import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/scholarship.dart';

Future<void> seedScholarships() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  final collection = firestore.collection('scholarships');

  final List<Scholarship> seeds = [
    // 1. National Merit Scholarship
    Scholarship(
      id: collection.doc().id,
      title: 'National Merit Scholarship',
      organization: 'Min. of Education',
      description:
          'For students with exceptional academic performance (CGPA > 9.0). Open to all categories.',
      amount: 50000,
      eligibilityCriteria: EligibilityCriteria(
        minIncome: 0,
        maxIncome: 1000000, // High limit
        categories: ['General', 'OBC', 'SC', 'ST', 'EWS'],
        courses: ['B.Tech', 'M.Tech', 'B.Sc', 'M.Sc'],
        years: [1, 2, 3, 4],
      ),
      deadline: DateTime.now().add(const Duration(days: 30)),
      createdBy: 'system_seed',
      createdAt: DateTime.now(),
    ),
    // 2. Post-Matric Scholarship for SC Students
    Scholarship(
      id: collection.doc().id,
      title: 'Post-Matric Scholarship (SC)',
      organization: 'Min. of Social Justice',
      description:
          'Financial assistance for Scheduled Caste students pursuing higher education.',
      amount: 30000,
      eligibilityCriteria: EligibilityCriteria(
        minIncome: 0,
        maxIncome: 250000,
        categories: ['SC'],
        courses: ['B.Tech', 'M.Tech'],
        years: [1, 2, 3, 4],
      ),
      deadline: DateTime.now().add(const Duration(days: 45)),
      createdBy: 'system_seed',
      createdAt: DateTime.now(),
    ),
    // 3. Post-Matric Scholarship for ST Students
    Scholarship(
      id: collection.doc().id,
      title: 'Post-Matric Scholarship (ST)',
      organization: 'Min. of Tribal Affairs',
      description:
          'Financial assistance for Scheduled Tribe students pursuing higher education.',
      amount: 30000,
      eligibilityCriteria: EligibilityCriteria(
        minIncome: 0,
        maxIncome: 250000,
        categories: ['ST'],
        courses: ['B.Tech', 'M.Tech'],
        years: [1, 2, 3, 4],
      ),
      deadline: DateTime.now().add(const Duration(days: 45)),
      createdBy: 'system_seed',
      createdAt: DateTime.now(),
    ),
    // 4. EWS Support Grant
    Scholarship(
      id: collection.doc().id,
      title: 'Economically Weaker Section Grant',
      organization: 'Central Government',
      description:
          'Tuition support for students from Economically Weaker Sections with varied backgrounds.',
      amount: 25000,
      eligibilityCriteria: EligibilityCriteria(
        minIncome: 0,
        maxIncome: 100000,
        categories: ['EWS'],
        courses: ['Any'],
        years: [1, 2, 3, 4],
      ),
      deadline: DateTime.now().add(const Duration(days: 20)),
      createdBy: 'system_seed',
      createdAt: DateTime.now(),
    ),
    // 5. OBC Merit-cum-Means Scholarship
    Scholarship(
      id: collection.doc().id,
      title: 'OBC Merit-cum-Means',
      organization: 'National OBC Commission',
      description:
          'For OBC students demonstrating both merit and financial need.',
      amount: 20000,
      eligibilityCriteria: EligibilityCriteria(
        minIncome: 0,
        maxIncome: 300000,
        categories: ['OBC'],
        courses: ['B.Tech'],
        years: [2, 3, 4],
      ),
      deadline: DateTime.now().add(const Duration(days: 60)),
      createdBy: 'system_seed',
      createdAt: DateTime.now(),
    ),
    // 6. Girls in STEM Scholarship
    Scholarship(
      id: collection.doc().id,
      title: 'Women in STEM Initiative',
      organization: 'Dept. of Science & Tech',
      description:
          'Encouraging female students in Engineering and Science fields. Open to all categories.',
      amount: 40000,
      eligibilityCriteria: EligibilityCriteria(
        minIncome: 0,
        maxIncome: 800000,
        categories: [
          'General',
          'OBC',
          'SC',
          'ST',
          'EWS',
        ], // Logic handle gender separately or assume applied by girls
        courses: ['B.Tech', 'B.Sc'],
        years: [1],
      ),
      deadline: DateTime.now().add(const Duration(days: 90)),
      createdBy: 'system_seed',
      createdAt: DateTime.now(),
    ),
    // 7. Research Excellence Grant
    Scholarship(
      id: collection.doc().id,
      title: 'Research Excellence Grant',
      organization: 'University Grants Commission',
      description:
          'For postgraduate students engaged in advanced research projects.',
      amount: 60000,
      eligibilityCriteria: EligibilityCriteria(
        minIncome: 0,
        maxIncome: 1500000,
        categories: ['General', 'OBC', 'SC', 'ST', 'EWS'],
        courses: ['M.Tech', 'M.Sc', 'PhD'],
        years: [1, 2],
      ),
      deadline: DateTime.now().add(const Duration(days: 30)),
      createdBy: 'system_seed',
      createdAt: DateTime.now(),
    ),
    // 8. Minority Welfare Scholarship
    Scholarship(
      id: collection.doc().id,
      title: 'Minority Welfare Scholarship',
      organization: 'Min. of Minority Affairs',
      description: 'Support for students from minority communities.',
      amount: 15000,
      eligibilityCriteria: EligibilityCriteria(
        minIncome: 0,
        maxIncome: 200000,
        categories: [
          'General',
          'OBC',
        ], // Often mapped to specific religious minorities, simplifying here
        courses: ['Any'],
        years: [1, 2, 3, 4],
      ),
      deadline: DateTime.now().add(const Duration(days: 40)),
      createdBy: 'system_seed',
      createdAt: DateTime.now(),
    ),
    // 9. Sports Quota Scholarship
    Scholarship(
      id: collection.doc().id,
      title: 'Sports Achiever Scholarship',
      organization: 'Sports Authority of India',
      description:
          'For students who have represented the state/nation in sports.',
      amount: 25000,
      eligibilityCriteria: EligibilityCriteria(
        minIncome: 0,
        maxIncome: 5000000,
        categories: ['General', 'OBC', 'SC', 'ST', 'EWS'],
        courses: ['Any'],
        years: [1, 2, 3, 4],
      ),
      deadline: DateTime.now().add(const Duration(days: 15)),
      createdBy: 'system_seed',
      createdAt: DateTime.now(),
    ),
    // 10. Physically Challenged Student Aid
    Scholarship(
      id: collection.doc().id,
      title: 'Divyangjan Study Aid',
      organization: 'Dept. of Empowerment of PwDs',
      description:
          'Financial support for differently-abled students for study materials and aids.',
      amount: 35000,
      eligibilityCriteria: EligibilityCriteria(
        minIncome: 0,
        maxIncome: 600000,
        categories: ['General', 'OBC', 'SC', 'ST', 'EWS'],
        courses: ['Any'],
        years: [1, 2, 3, 4],
      ),
      deadline: DateTime.now().add(const Duration(days: 50)),
      createdBy: 'system_seed',
      createdAt: DateTime.now(),
    ),
  ];

  for (final scholarship in seeds) {
    batch.set(collection.doc(scholarship.id), scholarship.toFirestore());
  }

  await batch.commit();
  debugPrint('Seeded 10 scholarships successfully!');
}
