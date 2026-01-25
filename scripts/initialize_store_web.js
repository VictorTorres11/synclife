// Web-based store initialization script
// Run this in the browser console when the app is loaded

async function initializeFluxoCoinsStore() {
  console.log('🚀 Initializing FluxoCoins Store...');
  
  // Check if Firebase is available
  if (typeof firebase === 'undefined') {
    console.error('❌ Firebase is not available. Make sure the app is loaded.');
    return;
  }

  const db = firebase.firestore();
  
  // Default store items
  const defaultItems = [
    // Functional Items
    {
      id: 'additional_board',
      name: 'Additional Board',
      description: 'Unlock an extra board to organize more projects',
      category: 'functional',
      price: 500,
      type: 'upgrade',
      iconPath: 'assets/store/additional_board.png',
      isAvailable: true,
      metadata: { maxPurchases: 5 }
    },
    {
      id: 'group_member_slot',
      name: 'Group Member Slot',
      description: 'Add one more member to your shared boards',
      category: 'functional',
      price: 300,
      type: 'upgrade',
      iconPath: 'assets/store/group_member.png',
      isAvailable: true,
      metadata: { maxPurchases: 10 }
    },
    {
      id: 'task_templates',
      name: 'Task Templates Pack',
      description: 'Pre-made task templates for common routines',
      category: 'functional',
      price: 200,
      type: 'permanent',
      iconPath: 'assets/store/task_templates.png',
      isAvailable: true
    },
    
    // Visual Items
    {
      id: 'dark_theme_premium',
      name: 'Premium Dark Theme',
      description: 'Elegant dark theme with custom colors',
      category: 'visual',
      price: 150,
      type: 'permanent',
      iconPath: 'assets/store/dark_theme.png',
      isAvailable: true
    },
    {
      id: 'nature_theme',
      name: 'Nature Theme',
      description: 'Calming green theme inspired by nature',
      category: 'visual',
      price: 150,
      type: 'permanent',
      iconPath: 'assets/store/nature_theme.png',
      isAvailable: true
    },
    {
      id: 'ocean_theme',
      name: 'Ocean Theme',
      description: 'Soothing blue theme with ocean vibes',
      category: 'visual',
      price: 150,
      type: 'permanent',
      iconPath: 'assets/store/ocean_theme.png',
      isAvailable: true
    },
    {
      id: 'achievement_sounds_pack',
      name: 'Achievement Sounds Pack',
      description: 'Collection of satisfying completion sounds',
      category: 'visual',
      price: 100,
      type: 'permanent',
      iconPath: 'assets/store/sounds_pack.png',
      isAvailable: true
    },
    {
      id: 'avatar_icons_pack',
      name: 'Avatar Icons Pack',
      description: 'Unique avatar icons to personalize your profile',
      category: 'visual',
      price: 75,
      type: 'permanent',
      iconPath: 'assets/store/avatar_pack.png',
      isAvailable: true
    },
    
    // Utility Items
    {
      id: 'streak_freeze',
      name: 'Streak Freeze',
      description: 'Protect your streak for one day if you miss tasks',
      category: 'utility',
      price: 50,
      type: 'consumable',
      iconPath: 'assets/store/streak_freeze.png',
      isAvailable: true,
      metadata: { maxQuantity: 5 }
    },
    {
      id: 'double_xp_boost',
      name: 'Double XP Boost',
      description: 'Earn double XP for 24 hours',
      category: 'utility',
      price: 100,
      type: 'consumable',
      iconPath: 'assets/store/xp_boost.png',
      isAvailable: true,
      metadata: { duration: '24h' }
    },
    {
      id: 'task_reminder_plus',
      name: 'Task Reminder Plus',
      description: 'Advanced reminder system with custom notifications',
      category: 'utility',
      price: 250,
      type: 'permanent',
      iconPath: 'assets/store/reminder_plus.png',
      isAvailable: true
    },
    {
      id: 'priority_support',
      name: 'Priority Support',
      description: 'Get priority customer support for 30 days',
      category: 'utility',
      price: 200,
      type: 'consumable',
      iconPath: 'assets/store/priority_support.png',
      isAvailable: true,
      metadata: { duration: '30d' }
    }
  ];

  try {
    // Use batch to add all items at once
    const batch = db.batch();
    
    defaultItems.forEach(item => {
      const docRef = db.collection('storeItems').doc(item.id);
      batch.set(docRef, item);
    });
    
    await batch.commit();
    
    console.log('✅ Store initialized successfully!');
    console.log(`📦 Added ${defaultItems.length} default items to the store`);
    
    // List the items that were added
    console.log('\n📋 Items added:');
    defaultItems.forEach(item => {
      console.log(`  • ${item.name} (${item.price} FluxoCoins) - ${item.category}`);
    });
    
    return true;
  } catch (error) {
    console.error('❌ Error initializing store:', error);
    return false;
  }
}

// Auto-run if this script is executed directly
if (typeof window !== 'undefined') {
  console.log('🔧 FluxoCoins Store Initialization Script Loaded');
  console.log('📝 Run initializeFluxoCoinsStore() to initialize the store');
}