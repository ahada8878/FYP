import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart'; // Assuming you have confetti package
import '../services/reward_service.dart';

class RedemptionShopScreen extends StatefulWidget {
  final int currentCoins;
  const RedemptionShopScreen({super.key, required this.currentCoins});

  @override
  State<RedemptionShopScreen> createState() => _RedemptionShopScreenState();
}

class _RedemptionShopScreenState extends State<RedemptionShopScreen> {
  final RewardService _rewardService = RewardService();
  late ConfettiController _confettiController;
  late int _userCoins;
  
  // Hardcoded list matching the Backend IDs
  final List<Map<String, dynamic>> _shopItems = [
    {
      'id': 'recipe_pack_1',
      'name': 'Keto Recipe Pack',
      'description': 'Unlock 20 exclusive low-carb recipes.',
      'cost': 200,
      'icon': Icons.restaurant_menu_rounded,
      'color': Colors.green
    },
    {
      'id': 'theme_dark',
      'name': 'Dark Mode',
      'description': 'Easy on the eyes. Unlock the dark theme.',
      'cost': 500,
      'icon': Icons.dark_mode_rounded,
      'color': Colors.indigo
    },
    {
      'id': 'badge_gold',
      'name': 'Golden Profile',
      'description': 'Add a shiny golden border to your avatar.',
      'cost': 1000,
      'icon': Icons.stars_rounded,
      'color': Colors.amber
    },
    {
      'id': 'consultation_15',
      'name': 'Expert Chat (15m)',
      'description': 'One-on-one chat with a nutritionist.',
      'cost': 5000,
      'icon': Icons.support_agent_rounded,
      'color': Colors.purple
    },
  ];

  Set<String> _ownedItems = {}; // Will fetch from API in real app
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userCoins = widget.currentCoins;
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    // ideally fetch _ownedItems from API here
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _buyItem(String itemId, int cost, String name) async {
    if (_userCoins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough coins! Keep walking! 🏃‍♂️"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _rewardService.redeemItem(itemId);
      
      setState(() {
        _userCoins = result['coins']; // Update local balance
        _ownedItems.add(itemId);
        _isLoading = false;
      });

      _confettiController.play();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Purchase Successful!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                Text("You unlocked '$name'. Check your settings/profile to use it!"),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Awesome"))],
          ),
        );
      }

    } catch (e) {
      setState(() => _isLoading = false);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Redeem Rewards', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Text("$_userCoins", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _shopItems.length,
            itemBuilder: (context, index) {
              final item = _shopItems[index];
              final isOwned = _ownedItems.contains(item['id']);
              return _buildShopCard(item, isOwned);
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 20,
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> item, bool isOwned) {
    final bool canAfford = _userCoins >= (item['cost'] as int);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item['icon'], color: item['color'], size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(item['description'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            isOwned
                ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                : ElevatedButton(
                    onPressed: canAfford ? () => _buyItem(item['id'], item['cost'], item['name']) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford ? Colors.orange : Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text("${item['cost']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}