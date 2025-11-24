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

  Future<void> _confirmPurchase(Map<String, dynamic> item) async {
    final primaryColor = Theme.of(context).primaryColor;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Redeem ${item['name']}?", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          "This will cost ${item['cost']} coins.\n\n"
          "We will automatically log this item to your Food Diary as a Snack.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          'Cheat Meal Shop', 
          style: TextStyle(
            color: primaryColor, 
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withOpacity(0.2))
            ),
            child: Row(
              children: [
                Icon(Icons.monetization_on_rounded, color: primaryColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  "$_userCoins", 
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)
                ),
              ],
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
            physics: const BouncingScrollPhysics(),
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.8), primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Earned your treat?", 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Redeem your hard-earned coins for guilt-free cheat meals. We'll handle the logging automatically.", 
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.4)
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Grid Layout
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72, // Slightly taller for button space
                ),
                itemCount: _shopItems.length,
                itemBuilder: (context, index) {
                  return _buildShopCard(_shopItems[index], primaryColor);
                },
              ),
            ],
          ),
          
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 25,
              gravity: 0.2,
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black12, 
              child: const Center(
                child: CircularProgressIndicator()
              )
            )
        ],
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> item, Color primaryColor) {
    final bool canAfford = _userCoins >= (item['cost'] as int);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Icon Circle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item['icon'], color: item['color'], size: 36),
          ),
          
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['name'], 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              item['desc'], 
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const Spacer(),
          
          // Buy Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: canAfford ? () => _confirmPurchase(item) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? primaryColor : Colors.grey.shade200,
                  foregroundColor: canAfford ? Colors.white : Colors.grey.shade400,
                  elevation: canAfford ? 2 : 0,
                  shadowColor: primaryColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (canAfford) ...[
                      const Icon(Icons.shopping_cart_rounded, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      "${item['cost']}", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: canAfford ? Colors.white : Colors.grey.shade500
                      )
                    ),
                    if (!canAfford) ...[
                      const SizedBox(width: 4),
                       Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey.shade500),
                    ]
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