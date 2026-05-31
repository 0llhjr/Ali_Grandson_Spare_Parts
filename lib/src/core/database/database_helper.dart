// ============================================================
// database_helper.dart — Central Database Manager (v12)
// ============================================================
// v12 additions:
//   • spare_part_products gains vehicle_type TEXT column
//   • getProducts / searchProducts fully dynamic (warehouseId,
//     brand, vehicleType, minPrice, maxPrice, inStockOnly)
//   • getDistinctBrands, getDistinctVehicleTypes,
//     getProductCountsByCategory, getMaxProductPrice helpers
// ============================================================

import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'alis_grandson.db'),
      version: 12,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── Schema Creation ──────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon TEXT NOT NULL DEFAULT 'category'
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        username TEXT PRIMARY KEY,
        name     TEXT NOT NULL,
        email    TEXT UNIQUE NOT NULL,
        phone    TEXT NOT NULL,
        password TEXT NOT NULL,
        dob      TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE admins(
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        email    TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE spare_part_products(
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        name         TEXT NOT NULL,
        description  TEXT,
        image        BLOB,
        type         TEXT,
        brand        TEXT,
        model        TEXT,
        vehicle_type TEXT,
        price        REAL NOT NULL,
        available    INTEGER NOT NULL,
        category_id  INTEGER REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE warehouses(
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT NOT NULL,
        address   TEXT NOT NULL,
        city      TEXT NOT NULL,
        phone     TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE warehouse_stock(
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
        product_id   INTEGER NOT NULL REFERENCES spare_part_products(id),
        quantity     INTEGER NOT NULL DEFAULT 0,
        UNIQUE(warehouse_id, product_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cart(
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        user_username TEXT NOT NULL,
        product_id    INTEGER NOT NULL,
        quantity      INTEGER NOT NULL,
        FOREIGN KEY (user_username) REFERENCES users (username),
        FOREIGN KEY (product_id)   REFERENCES spare_part_products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE orders(
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        user_username        TEXT NOT NULL,
        address              TEXT NOT NULL,
        phone                TEXT NOT NULL,
        special_instructions TEXT,
        payment_mode         TEXT NOT NULL,
        total_price          REAL NOT NULL,
        status               TEXT NOT NULL,
        order_date           TEXT NOT NULL,
        completion_date      TEXT,
        FOREIGN KEY (user_username) REFERENCES users (username)
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items(
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id   INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity   INTEGER NOT NULL,
        price      REAL NOT NULL,
        FOREIGN KEY (order_id)   REFERENCES orders (id),
        FOREIGN KEY (product_id) REFERENCES spare_part_products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE faqs(
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        answer   TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE wishlist(
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        user_username TEXT NOT NULL REFERENCES users(username),
        product_id    INTEGER NOT NULL REFERENCES spare_part_products(id),
        added_at      TEXT NOT NULL,
        UNIQUE(user_username, product_id)
      )
    ''');

    await seedFAQs(db);
    await db.insert('admins', {'email': 'admin', 'password': 'admin123'});
    await _seedCategories(db);
    await _seedWarehouses(db);
    await _seedSampleProducts(db);
  }

  // ── Schema Migration ─────────────────────────────────────────

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE users ADD COLUMN phone TEXT NOT NULL DEFAULT ""');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE cart(
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          user_username TEXT NOT NULL,
          product_id    INTEGER NOT NULL,
          quantity      INTEGER NOT NULL,
          FOREIGN KEY (user_username) REFERENCES users (username),
          FOREIGN KEY (product_id)   REFERENCES spare_part_products (id)
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE orders(
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          user_username TEXT NOT NULL,
          address       TEXT NOT NULL,
          phone         TEXT NOT NULL,
          payment_mode  TEXT NOT NULL,
          total_price   REAL NOT NULL,
          status        TEXT NOT NULL,
          order_date    TEXT NOT NULL,
          FOREIGN KEY (user_username) REFERENCES users (username)
        )
      ''');
      await db.execute('''
        CREATE TABLE order_items(
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id   INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          quantity   INTEGER NOT NULL,
          price      REAL NOT NULL,
          FOREIGN KEY (order_id)   REFERENCES orders (id),
          FOREIGN KEY (product_id) REFERENCES spare_part_products (id)
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE orders ADD COLUMN special_instructions TEXT');
    }
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE orders ADD COLUMN completion_date TEXT');
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE faqs(
          id       INTEGER PRIMARY KEY AUTOINCREMENT,
          question TEXT NOT NULL,
          answer   TEXT NOT NULL
        )
      ''');
      await seedFAQs(db);
    }
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE categories(
          id   INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          icon TEXT NOT NULL DEFAULT 'category'
        )
      ''');
      await db.execute('''
        CREATE TABLE warehouses(
          id        INTEGER PRIMARY KEY AUTOINCREMENT,
          name      TEXT NOT NULL,
          address   TEXT NOT NULL,
          city      TEXT NOT NULL,
          phone     TEXT,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE TABLE warehouse_stock(
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
          product_id   INTEGER NOT NULL REFERENCES spare_part_products(id),
          quantity     INTEGER NOT NULL DEFAULT 0,
          UNIQUE(warehouse_id, product_id)
        )
      ''');
      await db.execute('''
        CREATE TABLE wishlist(
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          user_username TEXT NOT NULL REFERENCES users(username),
          product_id    INTEGER NOT NULL REFERENCES spare_part_products(id),
          added_at      TEXT NOT NULL,
          UNIQUE(user_username, product_id)
        )
      ''');
      await db.execute('ALTER TABLE spare_part_products ADD COLUMN category_id INTEGER REFERENCES categories(id)');
      await _seedCategories(db);
      await _seedWarehouses(db);
    }
    if (oldVersion < 12) {
      await db.execute('ALTER TABLE spare_part_products ADD COLUMN vehicle_type TEXT');
    }
  }

  // ── Seed Helpers ─────────────────────────────────────────────

  Future<void> seedFAQs([Database? db]) async {
    final database = db ?? await instance.database;
    final faqs = [
      {'question': 'How do I place an order?',              'answer': ''},
      {'question': 'Where are your store locations?',       'answer': ''},
      {'question': 'What is your WhatsApp number for support?', 'answer': ''},
      {'question': 'What payment methods do you accept?',   'answer': ''},
      {'question': 'Is my payment information secure?',     'answer': ''},
      {'question': 'How long does delivery take?',          'answer': ''},
      {'question': 'What is your return policy?',           'answer': ''},
      {'question': 'How do I track my order?',              'answer': ''},
    ];
    for (final faq in faqs) {
      await database.insert('faqs', faq);
    }
  }

  Future<void> _seedCategories(Database db) async {
    final categories = [
      {'name': 'Engine Parts',          'icon': 'settings'},
      {'name': 'Brake System',          'icon': 'emergency_share'},
      {'name': 'Filters',               'icon': 'filter_alt'},
      {'name': 'Electrical',            'icon': 'bolt'},
      {'name': 'Suspension & Steering', 'icon': 'tune'},
      {'name': 'Body Parts',            'icon': 'directions_car'},
      {'name': 'Transmission',          'icon': 'swap_horiz'},
      {'name': 'Cooling System',        'icon': 'ac_unit'},
    ];
    for (final cat in categories) {
      await db.insert('categories', cat,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _seedWarehouses(Database db) async {
    final warehouses = [
      {'name': 'Muscat Main Warehouse', 'address': 'Industrial Area, Way 3014',   'city': 'Muscat',  'phone': '+968 2446 0000', 'is_active': 1},
      {'name': 'Salalah Branch',        'address': 'Salalah Industrial Estate',   'city': 'Salalah', 'phone': '+968 2329 0000', 'is_active': 1},
    ];
    for (final wh in warehouses) {
      await db.insert('warehouses', wh,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // category_id: 1=Engine 2=Brake 3=Filters 4=Electrical
  //              5=Suspension 6=Body 7=Transmission 8=Cooling
  Future<void> _seedSampleProducts(Database db) async {
    const warehouseId = 1;
    final products = <Map<String, dynamic>>[
      // ── Engine Parts ───────────────────────────────────────
      {'name':'Piston Ring Set','description':'Complete piston ring set for 4-cylinder engines. Standard size. Reduces oil consumption and restores compression.','type':'Engine','brand':'Toyota','model':'Camry 2.4L','vehicle_type':'Sedan','price':8.500,'available':15,'category_id':1},
      {'name':'Timing Belt Kit','description':'OEM-quality timing belt with tensioner and idler pulley. Replace every 90,000 km.','type':'Engine','brand':'Honda','model':'Accord 2.0L','vehicle_type':'Sedan','price':12.750,'available':10,'category_id':1},
      {'name':'Valve Cover Gasket','description':'Rubber-coated valve cover gasket. Prevents oil leaks from cylinder head.','type':'Engine','brand':'Nissan','model':'Altima 2.5L','vehicle_type':'Sedan','price':4.200,'available':20,'category_id':1},
      {'name':'Crankshaft Bearing Set','description':'Tri-metal crankshaft main bearing set, standard clearance. Restores oil pressure.','type':'Engine','brand':'Toyota','model':'Land Cruiser 4.0L','vehicle_type':'SUV','price':9.800,'available':8,'category_id':1},
      {'name':'Engine Mount (Front)','description':'Hydraulic engine mount. Significantly reduces cabin vibration and noise.','type':'Engine','brand':'Honda','model':'Civic 1.8L','vehicle_type':'Sedan','price':6.500,'available':12,'category_id':1},
      {'name':'Timing Chain Kit','description':'Heavy-duty timing chain with guides, tensioner, and all hardware. Prevents timing skip.','type':'Engine','brand':'Ford','model':'F-150 3.5L EcoBoost','vehicle_type':'Pickup Truck','price':18.900,'available':6,'category_id':1},
      {'name':'Camshaft Position Sensor','description':'OEM-spec camshaft sensor. Resolves P0340/P0341 fault codes. Plug-and-play fitment.','type':'Engine','brand':'Toyota','model':'Corolla 1.6L','vehicle_type':'Sedan','price':7.300,'available':14,'category_id':1},
      // ── Brake System ──────────────────────────────────────
      {'name':'Front Brake Pad Set','description':'Low-dust ceramic brake pads with audible wear indicators. Set of 4 pads.','type':'Brakes','brand':'Toyota','model':'Corolla 2014-2022','vehicle_type':'Sedan','price':5.500,'available':25,'category_id':2},
      {'name':'Front Brake Disc Rotor','description':'Vented cross-drilled rotor. OEM dimensions. Improves heat dissipation. Sold individually.','type':'Brakes','brand':'Honda','model':'Accord 2.4L','vehicle_type':'Sedan','price':11.200,'available':18,'category_id':2},
      {'name':'Rear Brake Caliper','description':'Remanufactured rear caliper with new seals and pistons. Includes brackets and hardware.','type':'Brakes','brand':'Nissan','model':'Pathfinder 3.5L','vehicle_type':'SUV','price':14.800,'available':7,'category_id':2},
      {'name':'Brake Master Cylinder','description':'Dual-circuit master cylinder with reservoir. Direct OEM replacement.','type':'Brakes','brand':'Toyota','model':'Land Cruiser 4.0L','vehicle_type':'SUV','price':19.500,'available':5,'category_id':2},
      {'name':'Rear Brake Drum','description':'Cast iron brake drum. Precision balanced for smooth, vibration-free braking.','type':'Brakes','brand':'Mitsubishi','model':'Lancer 1.6L','vehicle_type':'Sedan','price':8.900,'available':10,'category_id':2},
      {'name':'ABS Wheel Speed Sensor','description':'Magnetic ABS sensor for front axle. Resolves C0035/C0040 fault codes.','type':'Brakes','brand':'Toyota','model':'Camry 2.5L','vehicle_type':'Sedan','price':6.750,'available':16,'category_id':2},
      {'name':'Front Brake Flexible Hose','description':'Braided stainless-lined brake hose. Resists expansion under high braking pressure.','type':'Brakes','brand':'Universal','model':'All Models','vehicle_type':'Universal','price':2.800,'available':30,'category_id':2},
      // ── Filters ───────────────────────────────────────────
      {'name':'Engine Oil Filter','description':'High-filtration synthetic media oil filter. 3/4-16 thread. Filters particles down to 10 microns.','type':'Filter','brand':'Bosch','model':'Universal','vehicle_type':'Universal','price':1.200,'available':50,'category_id':3},
      {'name':'Engine Air Filter','description':'Panel-type cotton gauze air filter. Improves airflow by up to 10% vs paper OEM.','type':'Filter','brand':'Mann','model':'Toyota Corolla 1.6L','vehicle_type':'Sedan','price':2.500,'available':40,'category_id':3},
      {'name':'Fuel Filter (In-line)','description':'In-line fuel filter with 10-micron filtration media. Protects injectors from debris.','type':'Filter','brand':'Toyota','model':'Camry 2.5L','vehicle_type':'Sedan','price':3.800,'available':25,'category_id':3},
      {'name':'Cabin Air Filter','description':'Activated carbon cabin filter. Removes dust, pollen, and odours from passenger air.','type':'Filter','brand':'Mann','model':'Nissan Altima 2.5L','vehicle_type':'Sedan','price':3.200,'available':35,'category_id':3},
      {'name':'Automatic Transmission Filter Kit','description':'ATF filter with gasket and drain plug seal. Recommended every 40,000 km.','type':'Filter','brand':'Toyota','model':'Camry 2.5L','vehicle_type':'Sedan','price':5.600,'available':15,'category_id':3},
      {'name':'Diesel Fuel Filter','description':'Primary diesel filter with water separator bowl. Essential for diesel engine longevity.','type':'Filter','brand':'Mann','model':'Mitsubishi Pajero 3.2L','vehicle_type':'SUV','price':4.500,'available':12,'category_id':3},
      // ── Electrical ────────────────────────────────────────
      {'name':'Alternator 100A','description':'Remanufactured alternator. 100A output. Includes new voltage regulator and brushes.','type':'Electrical','brand':'Toyota','model':'Land Cruiser 4.0L','vehicle_type':'SUV','price':38.500,'available':4,'category_id':4},
      {'name':'Starter Motor','description':'1.4 kW starter motor. Plug-and-play replacement. Tested to 50,000 start cycles.','type':'Electrical','brand':'Honda','model':'Accord 2.4L','vehicle_type':'Sedan','price':29.900,'available':5,'category_id':4},
      {'name':'Ignition Coil Pack','description':'Individual ignition coil. Direct plug-in. Resolves P0300 random misfire codes.','type':'Electrical','brand':'Nissan','model':'Altima 2.5L','vehicle_type':'Sedan','price':8.750,'available':12,'category_id':4},
      {'name':'Iridium Spark Plug Set (4pcs)','description':'Iridium-tipped spark plugs with fine-wire electrode. 60,000 km service life.','type':'Electrical','brand':'NGK','model':'Toyota Corolla 1.6L','vehicle_type':'Sedan','price':4.500,'available':30,'category_id':4},
      {'name':'Car Battery 60Ah AGM','description':'Maintenance-free AGM battery. 12V 60Ah 540 CCA. Suitable for start-stop systems.','type':'Electrical','brand':'Panasonic','model':'Universal','vehicle_type':'Universal','price':22.000,'available':8,'category_id':4},
      {'name':'Headlight Bulb H4 (Pair)','description':'H4 halogen bulbs 60/55W. 30% brighter than standard. 3200K warm white output.','type':'Electrical','brand':'Osram','model':'Universal','vehicle_type':'Universal','price':3.500,'available':40,'category_id':4},
      {'name':'Oxygen (Lambda) Sensor','description':'4-wire wideband O2 sensor. Improves fuel economy. Resolves P0130/P0136 codes.','type':'Electrical','brand':'Bosch','model':'Toyota Camry 2.5L','vehicle_type':'Sedan','price':11.800,'available':10,'category_id':4},
      {'name':'MAP Sensor','description':'Manifold absolute pressure sensor. OEM-spec replacement. Resolves P0105 fault code.','type':'Electrical','brand':'Nissan','model':'Pathfinder 3.5L','vehicle_type':'SUV','price':9.200,'available':8,'category_id':4},
      // ── Suspension & Steering ─────────────────────────────
      {'name':'Front Shock Absorber','description':'Gas-charged mono-tube shock absorber. Restores ride quality and handling precision.','type':'Suspension','brand':'KYB','model':'Toyota Corolla 1.6L','vehicle_type':'Sedan','price':16.500,'available':8,'category_id':5},
      {'name':'Lower Control Arm','description':'Forged steel lower control arm with new ball joint and rubber bushings pre-installed.','type':'Suspension','brand':'Honda','model':'Accord 2.4L','vehicle_type':'Sedan','price':21.000,'available':6,'category_id':5},
      {'name':'Front Lower Ball Joint','description':'Heavy-duty ball joint with grease fitting. Eliminates steering clunks.','type':'Suspension','brand':'Nissan','model':'Pathfinder 3.5L','vehicle_type':'SUV','price':7.800,'available':10,'category_id':5},
      {'name':'Outer Tie Rod End','description':'Forged outer tie rod end. Requires wheel alignment after fitment.','type':'Suspension','brand':'Toyota','model':'Land Cruiser 4.0L','vehicle_type':'SUV','price':9.500,'available':9,'category_id':5},
      {'name':'Power Steering Rack','description':'Remanufactured hydraulic steering rack with new seals. Plug-and-play replacement.','type':'Suspension','brand':'Honda','model':'Civic 1.8L','vehicle_type':'Sedan','price':45.000,'available':3,'category_id':5},
      {'name':'Rear Strut Assembly','description':'Complete rear strut with spring, mount, and bearing pre-assembled. No workshop press needed.','type':'Suspension','brand':'Toyota','model':'Camry 2.5L','vehicle_type':'Sedan','price':19.800,'available':5,'category_id':5},
      {'name':'Stabilizer Bar Link','description':'Heavy-duty sway bar end link with grease nipple. Eliminates rattling over speed bumps.','type':'Suspension','brand':'Universal','model':'All Models','vehicle_type':'Universal','price':4.200,'available':20,'category_id':5},
      // ── Body Parts ────────────────────────────────────────
      {'name':'Side Mirror Assembly (Left)','description':'Powered, heated side mirror with integrated turn signal indicator. Plug-and-play.','type':'Body','brand':'Toyota','model':'Corolla 2014-2019','vehicle_type':'Sedan','price':12.500,'available':6,'category_id':6},
      {'name':'Front Bumper Cover','description':'Unpainted ABS plastic bumper cover. Primed and ready for painting. OEM fit.','type':'Body','brand':'Honda','model':'Accord 2016-2021','vehicle_type':'Sedan','price':28.000,'available':3,'category_id':6},
      {'name':'Hood Latch Assembly','description':'OEM-spec hood latch with safety catch. Direct bolt-on replacement.','type':'Body','brand':'Nissan','model':'Altima 2013-2018','vehicle_type':'Sedan','price':5.800,'available':8,'category_id':6},
      {'name':'Exterior Door Handle (Front Right)','description':'Chrome exterior door handle with key cylinder. Replaces broken or seized handles.','type':'Body','brand':'Toyota','model':'Land Cruiser 200','vehicle_type':'SUV','price':7.200,'available':10,'category_id':6},
      {'name':'Windshield Wiper Blade Set','description':'Frameless flat wiper blades. 26-inch driver side + 18-inch passenger. Universal fit.','type':'Body','brand':'Bosch','model':'Universal','vehicle_type':'Universal','price':3.900,'available':25,'category_id':6},
      {'name':'Tail Light Assembly (Right)','description':'Complete tail light with LED reverse and brake lights. Direct plug-in fitment.','type':'Body','brand':'Toyota','model':'Camry 2015-2020','vehicle_type':'Sedan','price':18.500,'available':4,'category_id':6},
      {'name':'Front Fender Liner (Left)','description':'High-density plastic splash guard. Protects engine bay from road debris and water.','type':'Body','brand':'Honda','model':'Civic 2016-2021','vehicle_type':'Sedan','price':6.400,'available':7,'category_id':6},
      // ── Transmission ──────────────────────────────────────
      {'name':'Clutch Kit (3-Piece)','description':'OEM-spec clutch disc, pressure plate, and release bearing. Restores smooth gear changes.','type':'Transmission','brand':'LUK','model':'Honda Civic 1.8L','vehicle_type':'Sedan','price':35.000,'available':4,'category_id':7},
      {'name':'Transmission Mount','description':'Solid rubber transmission mount. Reduces driveline vibration and clunking on gear changes.','type':'Transmission','brand':'Toyota','model':'Corolla 1.6L','vehicle_type':'Sedan','price':8.200,'available':10,'category_id':7},
      {'name':'Front CV Axle Shaft','description':'Remanufactured CV axle with new outer and inner boots, clamps, and grease included.','type':'Transmission','brand':'Honda','model':'Accord 2.4L','vehicle_type':'Sedan','price':29.500,'available':5,'category_id':7},
      {'name':'Gear Shift Cable','description':'Automatic transmission gear selector cable. OEM length and fittings.','type':'Transmission','brand':'Nissan','model':'Altima 2.5L','vehicle_type':'Sedan','price':11.900,'available':7,'category_id':7},
      {'name':'Torque Converter','description':'Remanufactured torque converter. Pressure-tested before shipping. 3-year warranty.','type':'Transmission','brand':'Toyota','model':'Land Cruiser 4.0L','vehicle_type':'SUV','price':75.000,'available':2,'category_id':7},
      // ── Cooling System ────────────────────────────────────
      {'name':'Aluminium Radiator','description':'Full-aluminium 2-row radiator. 30% better cooling capacity than OEM plastic unit.','type':'Cooling','brand':'Toyota','model':'Corolla 1.6L','vehicle_type':'Sedan','price':32.000,'available':5,'category_id':8},
      {'name':'Water Pump','description':'OEM-spec water pump with bearing, seal, and gasket included. Replace with timing belt.','type':'Cooling','brand':'Honda','model':'Accord 2.4L','vehicle_type':'Sedan','price':14.500,'available':9,'category_id':8},
      {'name':'Engine Thermostat','description':'Wax-element thermostat. Opens at 82°C. Includes housing O-ring seal.','type':'Cooling','brand':'Nissan','model':'Altima 2.5L','vehicle_type':'Sedan','price':3.800,'available':20,'category_id':8},
      {'name':'Dual Electric Cooling Fan Assembly','description':'Twin electric fan assembly with integrated controller module. Cures overheating.','type':'Cooling','brand':'Toyota','model':'Camry 2.5L','vehicle_type':'Sedan','price':22.000,'available':4,'category_id':8},
      {'name':'Upper Radiator Hose','description':'EPDM moulded radiator hose. Heat-resistant up to 150°C. Includes clamps.','type':'Cooling','brand':'Gates','model':'Universal','vehicle_type':'Universal','price':2.500,'available':30,'category_id':8},
      {'name':'Coolant Expansion Reservoir','description':'Translucent plastic coolant overflow tank with pressure cap. Direct OEM replacement.','type':'Cooling','brand':'Honda','model':'Civic 1.8L','vehicle_type':'Sedan','price':6.800,'available':8,'category_id':8},
      {'name':'Serpentine Drive Belt','description':'EPDM ribbed drive belt. Multi-rib K6 profile. Replace every 60,000 km.','type':'Cooling','brand':'Gates','model':'Universal','vehicle_type':'Universal','price':4.200,'available':25,'category_id':8},
    ];

    for (final product in products) {
      final productId = await db.insert('spare_part_products', product);
      await db.insert('warehouse_stock', {
        'warehouse_id': warehouseId,
        'product_id': productId,
        'quantity': product['available'],
      });
    }
  }

  // ── User Operations ───────────────────────────────────────────

  Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('users', row, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<bool> isUsernameTaken(String username) async {
    final db = await instance.database;
    final r = await db.query('users', where: 'username = ?', whereArgs: [username]);
    return r.isNotEmpty;
  }

  Future<bool> isEmailTaken(String email, [String? currentUsername]) async {
    final db = await instance.database;
    final r = await db.query('users',
        where: 'email = ? AND username != ?', whereArgs: [email, currentUsername]);
    return r.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await instance.database;
    return await db.query('users', orderBy: 'username ASC');
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'username = ?', whereArgs: [username]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<int> updateUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('users', row, where: 'username = ?', whereArgs: [row['username']]);
  }

  Future<int> updateUserPassword(String username, String newPassword) async {
    final db = await instance.database;
    return await db.update('users', {'password': newPassword},
        where: 'username = ?', whereArgs: [username]);
  }

  Future<int> deleteUser(String username) async {
    final db = await instance.database;
    return await db.delete('users', where: 'username = ?', whereArgs: [username]);
  }

  // ── Product Operations ────────────────────────────────────────

  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('spare_part_products', row);
  }

  /// Returns products with optional filters.
  ///
  /// When [warehouseId] is provided the stock column reflects
  /// that warehouse's quantity (via LEFT JOIN on warehouse_stock).
  /// Products with zero warehouse stock are excluded in that mode.
  Future<List<Map<String, dynamic>>> getProducts({
    String? filter,
    int? categoryId,
    int? warehouseId,
    String? brand,
    String? vehicleType,
    double? minPrice,
    double? maxPrice,
    bool inStockOnly = false,
  }) async {
    final db = await instance.database;

    final conds = <String>[];
    final args  = <dynamic>[];

    if (categoryId != null)               { conds.add('p.category_id = ?');  args.add(categoryId); }
    if (brand != null && brand.isNotEmpty){ conds.add('p.brand = ?');         args.add(brand); }
    if (vehicleType != null && vehicleType.isNotEmpty) { conds.add('p.vehicle_type = ?'); args.add(vehicleType); }
    if (minPrice != null)                 { conds.add('p.price >= ?');        args.add(minPrice); }
    if (maxPrice != null)                 { conds.add('p.price <= ?');        args.add(maxPrice); }

    if (warehouseId != null) {
      final stockCol = 'COALESCE(ws.quantity, 0)';
      if (filter == 'out_of_stock')      conds.add('$stockCol = 0');
      else if (filter == 'low_stock')    conds.add('$stockCol > 0 AND $stockCol < 10');
      else if (inStockOnly)              conds.add('$stockCol > 0');

      final where = conds.isNotEmpty ? 'WHERE ${conds.join(' AND ')}' : '';
      return await db.rawQuery('''
        SELECT p.id, p.name, p.description, p.type, p.brand, p.model,
               p.vehicle_type, p.price, p.category_id,
               COALESCE(ws.quantity, 0) AS available
        FROM spare_part_products p
        LEFT JOIN warehouse_stock ws
               ON ws.product_id = p.id AND ws.warehouse_id = ?
        $where
        ORDER BY p.id DESC
      ''', [warehouseId, ...args]);
    } else {
      if (filter == 'out_of_stock')      conds.add('p.available = 0');
      else if (filter == 'low_stock')    conds.add('p.available > 0 AND p.available < 10');
      else if (inStockOnly)              conds.add('p.available > 0');

      final where = conds.isNotEmpty ? 'WHERE ${conds.join(' AND ')}' : '';
      return await db.rawQuery('''
        SELECT p.id, p.name, p.description, p.type, p.brand, p.model,
               p.vehicle_type, p.price, p.available, p.category_id
        FROM spare_part_products p
        $where
        ORDER BY p.id DESC
      ''', args);
    }
  }

  Future<Map<String, dynamic>?> getProduct(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'spare_part_products',
      columns: ['id','name','description','type','brand','model','vehicle_type','price','available','category_id'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<Uint8List?> getProductImage(int id) async {
    final db = await instance.database;
    final maps = await db.query('spare_part_products',
        columns: ['image'], where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? maps.first['image'] as Uint8List? : null;
  }

  Future<int> updateProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('spare_part_products', row,
        where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('spare_part_products', where: 'id = ?', whereArgs: [id]);
  }

  /// Full-text + multi-filter product search.
  Future<List<Map<String, dynamic>>> searchProducts(
    String keyword, {
    int? categoryId,
    int? warehouseId,
    String? brand,
    String? vehicleType,
    double? minPrice,
    double? maxPrice,
    bool inStockOnly = false,
  }) async {
    final db = await instance.database;

    final conds = <String>[];
    final args  = <dynamic>[];

    if (keyword.isNotEmpty) {
      conds.add('(p.name LIKE ? OR p.description LIKE ? OR p.brand LIKE ?)');
      args.addAll(['%$keyword%', '%$keyword%', '%$keyword%']);
    }
    if (categoryId != null)                { conds.add('p.category_id = ?');   args.add(categoryId); }
    if (brand != null && brand.isNotEmpty) { conds.add('p.brand = ?');          args.add(brand); }
    if (vehicleType != null && vehicleType.isNotEmpty) { conds.add('p.vehicle_type = ?'); args.add(vehicleType); }
    if (minPrice != null)                  { conds.add('p.price >= ?');         args.add(minPrice); }
    if (maxPrice != null)                  { conds.add('p.price <= ?');         args.add(maxPrice); }

    if (warehouseId != null) {
      if (inStockOnly) conds.add('COALESCE(ws.quantity, 0) > 0');
      final where = conds.isNotEmpty ? 'WHERE ${conds.join(' AND ')}' : '';
      return await db.rawQuery('''
        SELECT p.id, p.name, p.description, p.type, p.brand, p.model,
               p.vehicle_type, p.price, p.category_id,
               COALESCE(ws.quantity, 0) AS available
        FROM spare_part_products p
        LEFT JOIN warehouse_stock ws
               ON ws.product_id = p.id AND ws.warehouse_id = ?
        $where
        ORDER BY p.id DESC
      ''', [warehouseId, ...args]);
    } else {
      if (inStockOnly) conds.add('p.available > 0');
      final where = conds.isNotEmpty ? 'WHERE ${conds.join(' AND ')}' : '';
      return await db.rawQuery('''
        SELECT p.id, p.name, p.description, p.type, p.brand, p.model,
               p.vehicle_type, p.price, p.available, p.category_id
        FROM spare_part_products p
        $where
        ORDER BY p.id DESC
      ''', args);
    }
  }

  // ── Filter Helper Queries ─────────────────────────────────────

  Future<List<String>> getDistinctBrands() async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT brand FROM spare_part_products WHERE brand IS NOT NULL AND brand != '' ORDER BY brand ASC");
    return rows.map((r) => r['brand'] as String).toList();
  }

  Future<List<String>> getDistinctVehicleTypes() async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT vehicle_type FROM spare_part_products WHERE vehicle_type IS NOT NULL AND vehicle_type != '' ORDER BY vehicle_type ASC");
    return rows.map((r) => r['vehicle_type'] as String).toList();
  }

  Future<Map<int, int>> getProductCountsByCategory() async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      'SELECT category_id, COUNT(*) AS cnt FROM spare_part_products WHERE category_id IS NOT NULL GROUP BY category_id');
    return { for (final r in rows) (r['category_id'] as int): (r['cnt'] as int) };
  }

  Future<double> getMaxProductPrice() async {
    final db = await instance.database;
    final rows = await db.rawQuery('SELECT MAX(price) AS mx FROM spare_part_products');
    return (rows.first['mx'] as num?)?.toDouble() ?? 100.0;
  }

  // ── Auth Operations ───────────────────────────────────────────

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final db = await instance.database;
    final maps = await db.query('users',
        where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<Map<String, dynamic>?> getAdmin(String email, String password) async {
    final db = await instance.database;
    final maps = await db.query('admins',
        where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return maps.isNotEmpty ? maps.first : null;
  }

  // ── Dashboard Statistics ──────────────────────────────────────

  Future<int> getUsersCount() async {
    final db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
  }

  Future<int> getProductsCount() async {
    final db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM spare_part_products')) ?? 0;
  }

  Future<int> getOutOfStockCount() async {
    final db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM spare_part_products WHERE available = 0')) ?? 0;
  }

  Future<int> getLowStockCount() async {
    final db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM spare_part_products WHERE available > 0 AND available < 10')) ?? 0;
  }

  Future<int> getPendingOrdersCount() async {
    final db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM orders WHERE status NOT IN ('Delivered','Cancelled')")) ?? 0;
  }

  Future<int> getCompletedOrdersCount() async {
    final db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM orders WHERE status = 'Delivered'")) ?? 0;
  }

  Future<double> getTotalRevenue() async {
    final db = await instance.database;
    final r = await db.rawQuery("SELECT SUM(total_price) FROM orders WHERE status = 'Delivered'");
    return (r.first.values.first as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getCurrentMonthRevenue() async {
    final db = await instance.database;
    final first = DateTime(DateTime.now().year, DateTime.now().month, 1).toString();
    final r = await db.rawQuery(
      "SELECT SUM(total_price) FROM orders WHERE status = 'Delivered' AND order_date >= ?", [first]);
    return (r.first.values.first as num?)?.toDouble() ?? 0.0;
  }

  // ── Revenue Analytics ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRevenueData(DateTime start, DateTime end) async {
    final db = await instance.database;
    return await db.query('orders',
        columns: ['order_date','total_price'],
        where: "status = 'Delivered' AND order_date BETWEEN ? AND ?",
        whereArgs: [start.toString(), end.toString()],
        orderBy: 'order_date ASC');
  }

  Future<List<Map<String, dynamic>>> getDetailedOrdersForRevenue(DateTime start, DateTime end) async {
    final db = await instance.database;
    return await db.query('orders',
        where: "status = 'Delivered' AND order_date BETWEEN ? AND ?",
        whereArgs: [start.toString(), end.toString()],
        orderBy: 'order_date DESC');
  }

  // ── Cart Operations ───────────────────────────────────────────

  Future<int> addToCart(String userUsername, int productId, int quantity) async {
    final db = await instance.database;
    final existing = await db.query('cart',
        where: 'user_username = ? AND product_id = ?', whereArgs: [userUsername, productId]);
    if (existing.isNotEmpty) {
      final newQty = (existing.first['quantity'] as int) + quantity;
      return await db.update('cart', {'quantity': newQty},
          where: 'id = ?', whereArgs: [existing.first['id']]);
    }
    return await db.insert('cart', {'user_username': userUsername, 'product_id': productId, 'quantity': quantity});
  }

  Future<List<Map<String, dynamic>>> getCartItems(String userUsername) async {
    final db = await instance.database;
    final cartItems = await db.query('cart', where: 'user_username = ?', whereArgs: [userUsername]);
    final products = <Map<String, dynamic>>[];
    for (final item in cartItems) {
      final p = await getProduct(item['product_id'] as int);
      if (p != null) {
        final merged = Map<String, dynamic>.from(p);
        merged['cart_id'] = item['id'];
        merged['quantity'] = item['quantity'];
        products.add(merged);
      }
    }
    return products;
  }

  Future<int> updateCartItem(int cartId, int quantity) async {
    final db = await instance.database;
    return await db.update('cart', {'quantity': quantity}, where: 'id = ?', whereArgs: [cartId]);
  }

  Future<int> deleteCartItem(int cartId) async {
    final db = await instance.database;
    return await db.delete('cart', where: 'id = ?', whereArgs: [cartId]);
  }

  Future<int> clearCart(String userUsername) async {
    final db = await instance.database;
    return await db.delete('cart', where: 'user_username = ?', whereArgs: [userUsername]);
  }

  // ── Order Operations ──────────────────────────────────────────

  Future<int> placeOrder(Map<String, dynamic> order, List<Map<String, dynamic>> items) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final orderId = await txn.insert('orders', order);
      for (final item in items) {
        await txn.insert('order_items', {
          'order_id': orderId, 'product_id': item['id'],
          'quantity': item['quantity'], 'price': item['price'],
        });
        await txn.rawUpdate(
          'UPDATE spare_part_products SET available = available - ? WHERE id = ?',
          [item['quantity'], item['id']]);
      }
      await txn.delete('cart', where: 'user_username = ?', whereArgs: [order['user_username']]);
      return orderId;
    });
  }

  Future<List<Map<String, dynamic>>> getUserOrders(String userUsername) async {
    final db = await instance.database;
    return await db.query('orders',
        where: 'user_username = ?', whereArgs: [userUsername], orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getAllOrders({String? filter}) async {
    final db = await instance.database;
    if (filter == 'pending')   return await db.query('orders', where: "status NOT IN ('Delivered','Cancelled')", orderBy: 'id DESC');
    if (filter == 'completed') return await db.query('orders', where: "status = 'Delivered'", orderBy: 'id DESC');
    return await db.query('orders', orderBy: 'id DESC');
  }

  Future<int> updateOrderStatus(int orderId, String status) async {
    final db = await instance.database;
    final values = <String, dynamic>{'status': status};
    if (status == 'Delivered' || status == 'Cancelled') {
      values['completion_date'] = DateTime.now().toString();
    }
    return await db.update('orders', values, where: 'id = ?', whereArgs: [orderId]);
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await instance.database;
    final items = await db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
    final detailed = <Map<String, dynamic>>[];
    for (final item in items) {
      final p = await getProduct(item['product_id'] as int);
      if (p != null) {
        final d = Map<String, dynamic>.from(item);
        d['product_name'] = p['name'];
        detailed.add(d);
      }
    }
    return detailed;
  }

  // ── FAQ Operations ────────────────────────────────────────────

  Future<int> insertFAQ(Map<String, dynamic> faq) async {
    final db = await instance.database;
    return await db.insert('faqs', faq);
  }

  Future<List<Map<String, dynamic>>> getAllFAQs() async {
    final db = await instance.database;
    return await db.query('faqs', orderBy: 'id ASC');
  }

  Future<int> updateFAQ(Map<String, dynamic> faq) async {
    final db = await instance.database;
    return await db.update('faqs', faq, where: 'id = ?', whereArgs: [faq['id']]);
  }

  Future<int> deleteFAQ(int id) async {
    final db = await instance.database;
    return await db.delete('faqs', where: 'id = ?', whereArgs: [id]);
  }

  // ── Category Operations ───────────────────────────────────────

  Future<int> insertCategory(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('categories', row, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await instance.database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getCategoryById(int id) async {
    final db = await instance.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<int> updateCategory(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('categories', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ── Warehouse Operations ──────────────────────────────────────

  Future<int> insertWarehouse(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('warehouses', row);
  }

  Future<List<Map<String, dynamic>>> getWarehouses() async {
    final db = await instance.database;
    return await db.query('warehouses', orderBy: 'id ASC');
  }

  Future<List<Map<String, dynamic>>> getActiveWarehouses() async {
    final db = await instance.database;
    return await db.query('warehouses', where: 'is_active = 1', orderBy: 'id ASC');
  }

  Future<Map<String, dynamic>?> getWarehouseById(int id) async {
    final db = await instance.database;
    final maps = await db.query('warehouses', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<int> updateWarehouse(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update('warehouses', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteWarehouse(int id) async {
    final db = await instance.database;
    return await db.delete('warehouses', where: 'id = ?', whereArgs: [id]);
  }

  // ── Warehouse Stock Operations ────────────────────────────────

  Future<int> setWarehouseStock(int warehouseId, int productId, int quantity) async {
    final db = await instance.database;
    final existing = await db.query('warehouse_stock',
        where: 'warehouse_id = ? AND product_id = ?', whereArgs: [warehouseId, productId]);
    int rows;
    if (existing.isNotEmpty) {
      rows = await db.update('warehouse_stock', {'quantity': quantity},
          where: 'warehouse_id = ? AND product_id = ?', whereArgs: [warehouseId, productId]);
    } else {
      await db.insert('warehouse_stock',
          {'warehouse_id': warehouseId, 'product_id': productId, 'quantity': quantity});
      rows = 1;
    }
    await recomputeProductAvailable(productId);
    return rows;
  }

  Future<List<Map<String, dynamic>>> getStockByProduct(int productId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT ws.id, ws.warehouse_id, ws.product_id, ws.quantity,
             w.name AS warehouse_name, w.city
      FROM warehouse_stock ws
      JOIN warehouses w ON w.id = ws.warehouse_id
      WHERE ws.product_id = ?
      ORDER BY w.name ASC
    ''', [productId]);
  }

  Future<List<Map<String, dynamic>>> getStockByWarehouse(int warehouseId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT ws.id, ws.warehouse_id, ws.product_id, ws.quantity,
             p.name AS product_name, p.brand, p.model, p.price
      FROM warehouse_stock ws
      JOIN spare_part_products p ON p.id = ws.product_id
      WHERE ws.warehouse_id = ?
      ORDER BY p.name ASC
    ''', [warehouseId]);
  }

  Future<void> recomputeProductAvailable(int productId) async {
    final db = await instance.database;
    await db.rawUpdate('''
      UPDATE spare_part_products
      SET available = (
        SELECT COALESCE(SUM(quantity), 0)
        FROM warehouse_stock WHERE product_id = ?
      )
      WHERE id = ?
    ''', [productId, productId]);
  }

  // ── Wishlist Operations ───────────────────────────────────────

  Future<int> addToWishlist(String username, int productId) async {
    final db = await instance.database;
    return await db.insert('wishlist', {
      'user_username': username,
      'product_id': productId,
      'added_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> removeFromWishlist(String username, int productId) async {
    final db = await instance.database;
    return await db.delete('wishlist',
        where: 'user_username = ? AND product_id = ?', whereArgs: [username, productId]);
  }

  Future<bool> isInWishlist(String username, int productId) async {
    final db = await instance.database;
    final r = await db.query('wishlist',
        where: 'user_username = ? AND product_id = ?', whereArgs: [username, productId]);
    return r.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getUserWishlist(String username) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT w.id AS wishlist_id, w.added_at,
             p.id, p.name, p.description, p.brand, p.model,
             p.vehicle_type, p.price, p.available, p.category_id
      FROM wishlist w
      JOIN spare_part_products p ON p.id = w.product_id
      WHERE w.user_username = ?
      ORDER BY w.added_at DESC
    ''', [username]);
  }
}
