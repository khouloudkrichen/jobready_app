import 'package:flutter/material.dart';
import '../../models/candidate_profile.dart';

class CertificationsSection extends StatelessWidget {
  final List<CertificationItem> certifications;
  const CertificationsSection({super.key, required this.certifications});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: certifications.map((c) => _CertCard(cert: c)).toList(),
    );
  }
}

class _CertCard extends StatelessWidget {
  final CertificationItem cert;
  const _CertCard({required this.cert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.verified_outlined,
              size: 18,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (cert.organisme.isNotEmpty || cert.annee.isNotEmpty)
                  Text(
                    [
                      cert.organisme,
                      cert.annee,
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
