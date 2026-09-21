import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(color: Color(0xFF121C2C), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF121C2C)),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF121C2C)),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Header
              const CircleAvatar(
                radius: 48,
                backgroundImage: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAoRGg6kRj97gu3ofbZx6h6wcyslpp3D_EE1bsgo_38VcvvuZHT-bzwefNDchZSI4c-wcadUygSHc4ng1P4xYmZnoBQ-f_GJ5DhRECEA86UtHvQ8YoNhOCznC06aOsMN66dh_1A_uAy88NSUPGvpYG22TbG4V3QzFFkcy6qFT6F8gA9bIEsYs69EoXnPugSF4A8O--H5Ee6HXK8GFXj6NBjhZbw35euiuAQsueCL8ZnEv6dGC6kV0Fs'),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? 'Traveler',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF121C2C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'No email',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_mall_outlined, size: 16, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Budget Traveler',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Profile Info Card
              _buildInfoCard(context, user),
              const SizedBox(height: 24),

              // Traveler Segment Card
              _buildSegmentCard(context),
              const SizedBox(height: 48),

              // Logout Button
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF121C2C)),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              )
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow('FULL NAME', user?.fullName ?? 'Traveler'),
          Divider(height: 32, thickness: 1, color: Colors.grey.shade200),
          _buildInfoRow('EMAIL', user?.email ?? 'No email'),
          Divider(height: 32, thickness: 1, color: Colors.grey.shade200),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoRow('PREFERENCES', 'Mountains, Road Trips'),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF121C2C)),
        ),
      ],
    );
  }

  Widget _buildSegmentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRAVELER SEGMENT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  'Frequent Budget Traveler',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF121C2C)),
                ),
                SizedBox(height: 4),
                Text(
                  'You love exploring new places without overspending.',
                  style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
