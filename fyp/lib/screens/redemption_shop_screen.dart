import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
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
  
  // ⭐️ 1. UPDATED CHEAT FOOD LIST
  // Must match keys in backend/controllers/rewardController.js
  final List<Map<String, dynamic>> _shopItems = [
    {
      'id': 'cheat_pizza',
      'name': 'Pepperoni Pizza',
      'desc': '298 kcal • Reward yourself!',
      'cost': 500,
      'icon': Icons.local_pizza_rounded,
      'color': Colors.deepOrange
    },
    {
      'id': 'cheat_burger',
      'name': 'Cheeseburger',
      'desc': '303 kcal • Classic treat.',
      'cost': 600,
      'icon': Icons.lunch_dining_rounded,
      'color': Colors.orange
    },
    {
      'id': 'cheat_fries',
      'name': 'French Fries',
      'desc': '365 kcal • Crispy & salty.',
      'cost': 350,
      'icon': Icons.fastfood_rounded,
      'color': Colors.amber
    },
    {
      'id': 'cheat_donut',
      'name': 'Glazed Donut',
      'desc': '269 kcal • Sweet tooth?',
      'cost': 250,
      'icon': Icons.bakery_dining_rounded,
      'color': Colors.pinkAccent
    },
    {
      'id': 'cheat_icecream',
      'name': 'Vanilla Cone',
      'desc': '207 kcal • Cool down.',
      'cost': 200,
      'icon': Icons.icecream_rounded,
      'color': Colors.blueAccent
    },
    {
      'id': 'cheat_soda',
      'name': 'Cola Can',
      'desc': '139 kcal • Bubbly refresh.',
      'cost': 150,
      'icon': Icons.local_drink_rounded,
      'color': Colors.redAccent
    },
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userCoins = widget.currentCoins;
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // ⭐️ 2. CONFIRMATION DIALOG
  Future<void> _confirmPurchase(Map<String, dynamic> item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Redeem ${item['name']}?"),
        content: Text(
          "This will cost ${item['cost']} coins.\n\n"
          "We will automatically log this item to your Food Diary as a Snack.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Confirm & Log", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _buyItem(item['id'], item['cost'], item['name']);
    }
  }

  Future<void> _buyItem(String itemId, int cost, String name) async {
    if (_userCoins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough coins! Burn more calories first! 🔥"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call API
      final result = await _rewardService.redeemItem(itemId);
      
      setState(() {
        _userCoins = result['coins']; 
        _isLoading = false;
      });

      _confettiController.play();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ $name redeemed and logged to diary!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      setState(() => _isLoading = false);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Purchase failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Cheat Meal Shop', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "Earned your treat?", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 4),
              Text(
                "Redeem coins for cheat meals. We'll handle the logging.", 
                style: TextStyle(fontSize: 14, color: Colors.grey[600])
              ),
              const SizedBox(height: 20),
              
              // Grid Layout for better shop feel
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _shopItems.length,
                itemBuilder: (context, index) {
                  return _buildShopCard(_shopItems[index]);
                },
              ),
            ],
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
            Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator()))
        ],
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> item) {
    final bool canAfford = _userCoins >= (item['cost'] as int);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item['icon'], color: item['color'], size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            item['name'], 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            item['desc'], 
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
             textAlign: TextAlign.center,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canAfford ? () => _confirmPurchase(item) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? Colors.orange : Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  elevation: canAfford ? 2 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text("${item['cost']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}