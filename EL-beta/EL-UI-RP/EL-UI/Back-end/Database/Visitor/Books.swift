//
//  Books.swift
//  EL
//
//  Created by WJR on 11/11/23.
//

import SQLite3
import UIKit
import CoreMedia
import CoreGraphics

// Keep the same API as before
enum ElementType {
  case original
  case crop
  case content
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class BooksDatabase {
  // MARK: - State
  private(set) var db: OpaquePointer?
  private let databaseQueue = DispatchQueue(label: "com.books.databaseQueue", qos: .userInitiated)
  private let queueKey = DispatchSpecificKey<Bool>()

  // Unified date parsing (CURRENT_TIMESTAMP -> "yyyy-MM-dd HH:mm:ss" UTC)
  private lazy var sqliteDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(secondsFromGMT: 0)
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return f
  }()

  // MARK: - Reentrancy-safe sync
  private func syncOnDB<T>(_ work: () -> T) -> T {
    if DispatchQueue.getSpecific(key: queueKey) == true {
      return work()               // Already on the DB queue: run directly to avoid a nested-sync trap
    } else {
      return databaseQueue.sync(execute: work)
    }
  }

  // MARK: - Init
  init() {
    databaseQueue.setSpecific(key: queueKey, value: true)
    openDatabase()
    createIndexTableIfNeeded()
    // Sensible PRAGMAs
    syncOnDB {
      _ = exec("PRAGMA foreign_keys = ON;")
      _ = exec("PRAGMA journal_mode = WAL;")
      _ = exec("PRAGMA synchronous = NORMAL;")
    }
    // Modified getBooksInfo call with sample data loading
    getBooksInfo { tables in
      print(tables)
      if !tables.map({ $0.name }).contains("dairy") {
        print("Need to create 'dairy' database")
        self.createTable(named: "dairy")
        
        var images: [CroppingImage] = []
        for i in 1...10 {
          guard let path = Bundle.main.path(forResource: String(i), ofType: "jpg") else { continue }
          if let image = UIImage(contentsOfFile: path) {
            images.append(CroppingImage(id: 0, image: image))
          }
        }
        print(images.count)
        
        if !images.isEmpty {
          self.addOriginal(originals: images, to: "dairy", chapterId: 0)
          print("Successfully loaded images into the 'dairy' table.")
        } else {
          print("No images found to load into the 'dairy' table.")
        }
      }
    }
  }

  // MARK: - Helpers
  private func sanitizeTableName(_ raw: String) -> String {
    // Allow letters, digits and underscores; if more characters are needed, relax this rule or use double-quoted identifiers instead (this file already double-quotes identifiers)
    let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "_"))
    if raw.unicodeScalars.allSatisfy({ allowed.contains($0) }) {
      return raw
    }
    // No longer triggers an assertion; apply a "soft filter" first, then wrap in double quotes, to avoid a trap in Debug builds
    let filtered = String(raw.unicodeScalars.filter { allowed.contains($0) })
    return filtered.isEmpty ? "book" : filtered
  }

  @discardableResult
  private func exec(_ sql: String) -> Bool {
    guard let db = db else { return false }
    var err: UnsafeMutablePointer<Int8>?
    if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK {
      if let e = err { print("SQLite exec error: \(String(cString: e)) | SQL: \(sql)"); sqlite3_free(e) }
      return false
    }
    return true
  }

  private func prepare(_ sql: String, _ stmt: inout OpaquePointer?) -> Bool {
    guard let db = db else { return false }
    let rc = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
    if rc != SQLITE_OK {
      if let err = sqlite3_errmsg(db) {
        print("SQLite prepare error: \(String(cString: err)) | SQL: \(sql)")
      }
      return false
    }
    return true
  }

  private func ident(_ name: String) -> String {
    // Quote identifiers with double quotes to allow a wider range of characters (safer even after sanitizing)
    return "\"\(name)\""
  }

  // MARK: - Open / IndexTable
  func openDatabase() {
    let fileURL = try! FileManager.default
      .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      .appendingPathComponent("Books.db")

    syncOnDB {
      if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
        print("Error opening database")
      } else {
        print("Successfully opened connection to database at \(fileURL.path)")
      }
    }
  }

  func createIndexTableIfNeeded() {
    let sql = """
    CREATE TABLE IF NOT EXISTS "IndexTable"(
      name TEXT PRIMARY KEY NOT NULL,
      coverImage BLOB,
      addTime DATETIME DEFAULT CURRENT_TIMESTAMP,
      finalChangeTime DATETIME DEFAULT CURRENT_TIMESTAMP,
      pageNumber INTEGER NOT NULL DEFAULT 0
    );
    """
    syncOnDB { _ = exec(sql) }
  }

  // MARK: - Public Ops (same API)
  func addOperation(_ data: Any, in tableName: String, chapterId: Int) {
    let t = sanitizeTableName(tableName)
    updateFinalChangeTime(named: t)
    updatePageNumber(named: t, change: "+")
    addOriginal(originals: [data], to: t, chapterId: chapterId)
  }

  func changeOperation(_ elementType: ElementType, _ newData: Any, at index: Int, from tableName: String) {
    let t = sanitizeTableName(tableName)
    updateFinalChangeTime(named: t)
    switch elementType {
    case .original:
      if let img = newData as? UIImage {
        changeOriginal(at: index, newOriginal: img, in: t)
      } else if let ci = newData as? CroppingImage {
        changeOriginal(at: index, newOriginal: (ci.image as Any), in: t)
      } else if let d = newData as? Data, let img = UIImage(data: d) {
        changeOriginal(at: index, newOriginal: img, in: t)
      } else {
        print("changeOperation(.original) unsupported type")
      }
    case .crop:
      changeCrop(at: index, newCrop: newData, in: t)
    case .content:
      if let pc = newData as? PageContent {
        changeContent(at: index, newContent: pc, in: t)
      } else {
        print("changeOperation(.content) expects PageContent")
      }
    }
  }

  func deleteOperation(_ elementType: ElementType, at index: Int, from tableName: String) {
    let t = sanitizeTableName(tableName)
    updateFinalChangeTime(named: t)
    switch elementType {
    case .original:
      deleteOriginal(at: index, from: t)
      updatePageNumber(named: t, change: "-")
    case .crop:
      deleteCrop(at: index, from: t)
    case .content:
      deleteContent(at: index, from: t)
    }
  }

  func getOperation(_ elementType: ElementType, at indexes: [Int], from tableName: String) -> Any? {
    let t = sanitizeTableName(tableName)
    switch elementType {
    case .original: return getOriginal(at: indexes, from: t)
    case .crop:     return getCrop(at: indexes, from: t)
    case .content:  return getContent(at: indexes, from: t)
    }
  }

  // MARK: - Table Ops
  func createTable(named tableName: String) {
    let t = sanitizeTableName(tableName)
    let sql = """
    CREATE TABLE IF NOT EXISTS \(ident(t)) (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      ChapterId INTEGER,
      EntryDate DATETIME DEFAULT CURRENT_TIMESTAMP,
      Type TEXT,
      Original BLOB,
      Crop TEXT,
      Words TEXT,
      Positions TEXT,
      Pointer TEXT
    );
    """
    syncOnDB {
      if exec(sql) {
        ensureIndicesForTable(t)
        updateIndexTable_NoSync(with: t)
        print("\(t) table successfully created.")
      } else {
        print("\(t) table could not be created.")
      }
    }
  }

  private func ensureIndicesForTable(_ table: String) {
    // Wrap in double quotes to avoid name clashes; quote index names too
    _ = exec("CREATE INDEX IF NOT EXISTS \(ident("idx_\(table)_chapter")) ON \(ident(table))(ChapterId);")
    _ = exec("CREATE INDEX IF NOT EXISTS \(ident("idx_\(table)_entrydate")) ON \(ident(table))(EntryDate);")
  }

  private func updateIndexTable_NoSync(with tableName: String) {
    let sql = """
      INSERT OR IGNORE INTO "IndexTable" (name, addTime, finalChangeTime, pageNumber)
      VALUES (?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0);
    """
    var stmt: OpaquePointer?
    guard prepare(sql, &stmt) else { return }
    defer { sqlite3_finalize(stmt) }
    sqlite3_bind_text(stmt, 1, (tableName as NSString).utf8String, -1, SQLITE_TRANSIENT)
    if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
      print("IndexTable insert error: \(String(cString: err))")
    }
  }

  func changeTableName(from oldTableName: String, to newTableName: String) {
    let old = sanitizeTableName(oldTableName)
    let new = sanitizeTableName(newTableName)
    let sql = "ALTER TABLE \(ident(old)) RENAME TO \(ident(new));"
    syncOnDB {
      if exec(sql) {
        updateIndexTableForRename_NoSync(from: old, to: new)
        print("Table \(old) successfully renamed to \(new).")
      } else {
        print("Could not rename table \(old) to \(new).")
      }
    }
  }

  private func updateIndexTableForRename_NoSync(from oldTableName: String, to newTableName: String) {
    let sql = """
      UPDATE "IndexTable" SET name = ?, finalChangeTime = CURRENT_TIMESTAMP WHERE name = ?;
    """
    var stmt: OpaquePointer?
    guard prepare(sql, &stmt) else { return }
    defer { sqlite3_finalize(stmt) }
    sqlite3_bind_text(stmt, 1, (newTableName as NSString).utf8String, -1, SQLITE_TRANSIENT)
    sqlite3_bind_text(stmt, 2, (oldTableName as NSString).utf8String, -1, SQLITE_TRANSIENT)
    if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
      print("IndexTable rename update error: \(String(cString: err))")
    }
  }

  func deleteTable(named tableName: String) {
    let t = sanitizeTableName(tableName)
    let sql = "DROP TABLE IF EXISTS \(ident(t));"
    syncOnDB {
      if exec(sql) {
        removeFromIndexTable_NoSync(tableName: t)
        print("Table \(t) successfully deleted.")
      } else {
        print("Could not delete table \(t).")
      }
    }
  }

  private func removeFromIndexTable_NoSync(tableName: String) {
    let sql = "DELETE FROM \"IndexTable\" WHERE name = ?;"
    var stmt: OpaquePointer?
    guard prepare(sql, &stmt) else { return }
    defer { sqlite3_finalize(stmt) }
    sqlite3_bind_text(stmt, 1, (tableName as NSString).utf8String, -1, SQLITE_TRANSIENT)
    if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
      print("IndexTable delete error: \(String(cString: err))")
    }
  }

  func addOrUpdateCoverForTable(named tableName: String, coverImage: UIImage) {
    let t = sanitizeTableName(tableName)
    guard let data = coverImage.pngData() else {
      print("Error converting image to PNG data"); return
    }
    syncOnDB {
      var exists = false
      do {
        let sql = "SELECT EXISTS(SELECT 1 FROM \"IndexTable\" WHERE name = ? LIMIT 1);"
        var stmt: OpaquePointer?
        guard prepare(sql, &stmt) else { return }
        sqlite3_bind_text(stmt, 1, (t as NSString).utf8String, -1, SQLITE_TRANSIENT)
        if sqlite3_step(stmt) == SQLITE_ROW { exists = sqlite3_column_int(stmt, 0) != 0 }
        sqlite3_finalize(stmt)
      }

      if exists {
        let sql = "UPDATE \"IndexTable\" SET coverImage = ?, finalChangeTime = CURRENT_TIMESTAMP WHERE name = ?;"
        var stmt: OpaquePointer?
        guard prepare(sql, &stmt) else { return }
        data.withUnsafeBytes { buf in sqlite3_bind_blob(stmt, 1, buf.baseAddress, Int32(data.count), SQLITE_TRANSIENT) }
        sqlite3_bind_text(stmt, 2, (t as NSString).utf8String, -1, SQLITE_TRANSIENT)
        if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
          print("Cover update error: \(String(cString: err))")
        }
        sqlite3_finalize(stmt)
      } else {
        let sql = """
          INSERT INTO "IndexTable" (name, coverImage, addTime, finalChangeTime, pageNumber)
          VALUES (?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0);
        """
        var stmt: OpaquePointer?
        guard prepare(sql, &stmt) else { return }
        sqlite3_bind_text(stmt, 1, (t as NSString).utf8String, -1, SQLITE_TRANSIENT)
        data.withUnsafeBytes { buf in sqlite3_bind_blob(stmt, 2, buf.baseAddress, Int32(data.count), SQLITE_TRANSIENT) }
        if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
          print("Cover insert error: \(String(cString: err))")
        }
        sqlite3_finalize(stmt)
      }
    }
  }

  func getBooksInfo(completion: @escaping ([BookInfo]) -> Void) {
    let sql = "SELECT name, coverImage, addTime, finalChangeTime, pageNumber FROM \"IndexTable\";"
    var results = [BookInfo]()
    syncOnDB {
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return }
      defer { sqlite3_finalize(stmt) }
      while sqlite3_step(stmt) == SQLITE_ROW {
        let name = String(cString: sqlite3_column_text(stmt, 0))
        var cover: UIImage? = nil
        if let blob = sqlite3_column_blob(stmt, 1) {
          let size = Int(sqlite3_column_bytes(stmt, 1))
          cover = UIImage(data: Data(bytes: blob, count: size))
        }
        let add = String(cString: sqlite3_column_text(stmt, 2))
        let fin = String(cString: sqlite3_column_text(stmt, 3))
        let pages = Int(sqlite3_column_int(stmt, 4))
        let addTime = sqliteDateFormatter.date(from: add) ?? Date()
        let finalTime = sqliteDateFormatter.date(from: fin) ?? Date()
        results.append(BookInfo(name: name, coverImage: cover, addTime: addTime, finalOpenTime: finalTime, pageNumber: pages))
      }
    }
    completion(results) // Callback outside the queue
  }

  func updateFinalChangeTime(named tableName: String) {
    let t = sanitizeTableName(tableName)
    let sql = "UPDATE \"IndexTable\" SET finalChangeTime = CURRENT_TIMESTAMP WHERE name = ?;"
    syncOnDB {
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return }
      sqlite3_bind_text(stmt, 1, (t as NSString).utf8String, -1, SQLITE_TRANSIENT)
      if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
        print("updateFinalChangeTime error: \(String(cString: err))")
      }
      sqlite3_finalize(stmt)
    }
  }

  func updatePageNumber(named tableName: String, change: String) {
    let t = sanitizeTableName(tableName)
    let sql: String = (change == "+")
      ? "UPDATE \"IndexTable\" SET pageNumber = pageNumber + 1 WHERE name = ?;"
      : (change == "-")
        ? "UPDATE \"IndexTable\" SET pageNumber = CASE WHEN pageNumber <= 0 THEN 0 ELSE pageNumber - 1 END WHERE name = ?;"
        : ""
    guard !sql.isEmpty else { return }
    syncOnDB {
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return }
      sqlite3_bind_text(stmt, 1, (t as NSString).utf8String, -1, SQLITE_TRANSIENT)
      if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
        print("updatePageNumber error: \(String(cString: err))")
      }
      sqlite3_finalize(stmt)
    }
  }

  func getAllIds(from tableName: String, chapterId: Int?) -> [Int] {
    let t = sanitizeTableName(tableName)
    return syncOnDB {
      var ids: [Int] = []
      let sql = (chapterId != nil)
        ? "SELECT ID FROM \(ident(t)) WHERE ChapterId = ? ORDER BY ID ASC;"
        : "SELECT ID FROM \(ident(t)) ORDER BY ID ASC;"
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return [] }
      defer { sqlite3_finalize(stmt) }
      if let cid = chapterId { sqlite3_bind_int(stmt, 1, Int32(cid)) }
      while sqlite3_step(stmt) == SQLITE_ROW { ids.append(Int(sqlite3_column_int(stmt, 0))) }
      return ids
    }
  }

  func getAllChapterIds(from tableName: String) -> [(Int, [Int])] {
    let t = sanitizeTableName(tableName)
    return syncOnDB {
      var dict: [Int: [Int]] = [:]
      let sql = "SELECT ChapterId, ID FROM \(ident(t)) ORDER BY ChapterId ASC, ID ASC;"
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return [] }
      defer { sqlite3_finalize(stmt) }
      while sqlite3_step(stmt) == SQLITE_ROW {
        let cid = Int(sqlite3_column_int(stmt, 0))
        let id  = Int(sqlite3_column_int(stmt, 1))
        dict[cid, default: []].append(id)
      }
      return dict.map { ($0.key, $0.value) }
    }
  }

  // MARK: - Original
  public func addOriginal(originals: [Any], to tableName: String, chapterId: Int) {
    let t = sanitizeTableName(tableName)
    syncOnDB {
      guard exec("BEGIN IMMEDIATE TRANSACTION;") else { return }
      defer { _ = exec("COMMIT;") }
      let sql = "INSERT INTO \(ident(t)) (EntryDate, Type, Original, ChapterId) VALUES (CURRENT_TIMESTAMP, ?, ?, ?);"
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return }
      defer { sqlite3_finalize(stmt) }
      for original in originals {
        var uiImage: UIImage?
        if let ci = original as? CroppingImage { uiImage = ci.image }
        else if let img = original as? UIImage { uiImage = img }
        else if let data = original as? Data { uiImage = UIImage(data: data) }
        guard let image = uiImage, let data = image.jpegData(compressionQuality: 1.0) else {
          print("Invalid original data: \(original)"); continue
        }
        let typeStr = "UIImage"
        sqlite3_bind_text(stmt, 1, (typeStr as NSString).utf8String, -1, SQLITE_TRANSIENT)
        data.withUnsafeBytes { buf in sqlite3_bind_blob(stmt, 2, buf.baseAddress, Int32(data.count), SQLITE_TRANSIENT) }
        sqlite3_bind_int(stmt, 3, Int32(chapterId))
        if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
          print("Could not insert row. Error: \(String(cString: err))")
        }
        sqlite3_reset(stmt); sqlite3_clear_bindings(stmt)
      }
    }
  }

  public func changeOriginal(at index: Int, newOriginal: Any, in tableName: String) {
    let t = sanitizeTableName(tableName)
    syncOnDB {
      var image: UIImage?
      if let img = newOriginal as? UIImage { image = img }
      else if let ci = newOriginal as? CroppingImage { image = ci.image }
      else if let data = newOriginal as? Data { image = UIImage(data: data) }
      guard let final = image, let data = final.jpegData(compressionQuality: 1.0) else {
        print("changeOriginal: invalid data"); return
      }
      let sql = "UPDATE \(ident(t)) SET Type = ?, Original = ?, EntryDate = CURRENT_TIMESTAMP WHERE ID = ?;"
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return }
      defer { sqlite3_finalize(stmt) }
      let typeStr = "UIImage"
      sqlite3_bind_text(stmt, 1, (typeStr as NSString).utf8String, -1, SQLITE_TRANSIENT)
      data.withUnsafeBytes { buf in sqlite3_bind_blob(stmt, 2, buf.baseAddress, Int32(data.count), SQLITE_TRANSIENT) }
      sqlite3_bind_int(stmt, 3, Int32(index))
      if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
        print("changeOriginal error: \(String(cString: err))")
      }
    }
  }

  public func deleteOriginal(at index: Int, from tableName: String) {
    let t = sanitizeTableName(tableName)
    let sql = "DELETE FROM \(ident(t)) WHERE ID = ?;"
    syncOnDB {
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return }
      defer { sqlite3_finalize(stmt) }
      sqlite3_bind_int(stmt, 1, Int32(index))
      if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
        print("deleteOriginal error: \(String(cString: err))")
      }
    }
  }

  public func getOriginal(at index: [Int], from tableName: String) -> [(type: String?, original: UIImage?)] {
    let t = sanitizeTableName(tableName)
    return syncOnDB {
      guard !index.isEmpty else { return [] }
      let ids = index.map(String.init).joined(separator: ",")
      let order = index.enumerated().map { "WHEN \(ident(t)).ID = \($0.element) THEN \($0.offset)" }.joined(separator: " ")
      let sql = """
      SELECT Type, Original FROM \(ident(t))
      WHERE ID IN (\(ids))
      ORDER BY CASE \(order) END;
      """
      var out: [(String?, UIImage?)] = []
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return [] }
      defer { sqlite3_finalize(stmt) }
      while sqlite3_step(stmt) == SQLITE_ROW {
        let typeStr = sqlite3_column_text(stmt, 0).flatMap { String(cString: $0) }
        var img: UIImage? = nil
        if let blob = sqlite3_column_blob(stmt, 1) {
          let size = Int(sqlite3_column_bytes(stmt, 1))
          img = UIImage(data: Data(bytes: blob, count: size))
        }
        out.append((typeStr, img))
      }
      return out
    }
  }

  // MARK: - Crop
  public func addCrop(at index: Any?, crop: Any, to tableName: String) {
    let t = sanitizeTableName(tableName)
    syncOnDB {
      let cropText = encodeCrop(crop)
      guard let targetId = resolveTargetId(table: t, index: index) else {
        print("addCrop: cannot resolve target row id"); return
      }
      let sql = "UPDATE \(ident(t)) SET Crop = ? WHERE ID = ?;"
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return }
      defer { sqlite3_finalize(stmt) }
      sqlite3_bind_text(stmt, 1, (cropText as NSString).utf8String, -1, SQLITE_TRANSIENT)
      sqlite3_bind_int(stmt, 2, Int32(targetId))
      if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
        print("addCrop error: \(String(cString: err))")
      }
    }
  }

  public func changeCrop(at index: Int, newCrop: Any, in tableName: String) {
    let t = sanitizeTableName(tableName)
    syncOnDB {
      let cropText = encodeCrop(newCrop)
      let sql = "UPDATE \(ident(t)) SET Crop = ? WHERE ID = ?;"
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return }
      defer { sqlite3_finalize(stmt) }
      sqlite3_bind_text(stmt, 1, (cropText as NSString).utf8String, -1, SQLITE_TRANSIENT)
      sqlite3_bind_int(stmt, 2, Int32(index))
      if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
        print("changeCrop error: \(String(cString: err))")
      }
    }
  }

  public func deleteCrop(at index: Int, from tableName: String) {
    let t = sanitizeTableName(tableName)
    let sql = "UPDATE \(ident(t)) SET Crop = NULL WHERE ID = ?;"
    syncOnDB {
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return }
      defer { sqlite3_finalize(stmt) }
      sqlite3_bind_int(stmt, 1, Int32(index))
      if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
        print("deleteCrop error: \(String(cString: err))")
      }
    }
  }

  public func getCrop(at index: [Int], from tableName: String) -> [Any]? {
    let t = sanitizeTableName(tableName)
    return syncOnDB {
      guard !index.isEmpty else { return [] }
      let ids = index.map(String.init).joined(separator: ",")
      let order = index.enumerated().map { "WHEN \(ident(t)).ID = \($0.element) THEN \($0.offset)" }.joined(separator: " ")
      let sql = """
      SELECT Crop FROM \(ident(t))
      WHERE ID IN (\(ids))
      ORDER BY CASE \(order) END;
      """
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return [] }
      defer { sqlite3_finalize(stmt) }
      var crops: [Any] = []
      while sqlite3_step(stmt) == SQLITE_ROW {
        if let c = sqlite3_column_text(stmt, 0) {
          let s = String(cString: c)
          let decoded = decodePositions(s)
          if decoded.isEmpty && !s.isEmpty { crops.append(s) } else { crops.append(decoded) }
        } else {
          crops.append(NSNull())
        }
      }
      return crops
    }
  }

  // MARK: - Words / Positions / Pointer
  public func addContent(at index: Int, content: PageContent, to tableName: String) {
    let t = sanitizeTableName(tableName)
    syncOnDB {
      let wordsText = content.texts.joined(separator: " ")
      let positionsText = normalizePositionsToString(content.positions) ?? ""
      let pointerText = encodePointer(content.pointer)
      let sql = "UPDATE \(ident(t)) SET Words = ?, Positions = ?, Pointer = ? WHERE ID = ?;"
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return }
      defer { sqlite3_finalize(stmt) }
      sqlite3_bind_text(stmt, 1, (wordsText as NSString).utf8String, -1, SQLITE_TRANSIENT)
      sqlite3_bind_text(stmt, 2, (positionsText as NSString).utf8String, -1, SQLITE_TRANSIENT)
      sqlite3_bind_text(stmt, 3, (pointerText as NSString).utf8String, -1, SQLITE_TRANSIENT)
      sqlite3_bind_int(stmt, 4, Int32(index))
      if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
        print("addContent error: \(String(cString: err))")
      }
    }
  }

  public func changeContent(at index: Int, newContent: PageContent, in tableName: String) {
    addContent(at: index, content: newContent, to: tableName)
  }

  public func deleteContent(at index: Int, from tableName: String) {
    let t = sanitizeTableName(tableName)
    let sql = "UPDATE \(ident(t)) SET Words = NULL, Positions = NULL, Pointer = NULL WHERE ID = ?;"
    syncOnDB {
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return }
      defer { sqlite3_finalize(stmt) }
      sqlite3_bind_int(stmt, 1, Int32(index))
      if sqlite3_step(stmt) != SQLITE_DONE, let err = sqlite3_errmsg(db) {
        print("deleteContent error: \(String(cString: err))")
      }
    }
  }

  public func getContent(at index: [Int], from tableName: String) -> [PageContent?] {
    let t = sanitizeTableName(tableName)
    return syncOnDB {
      guard !index.isEmpty else { return [] }
      let ids = index.map(String.init).joined(separator: ",")
      let order = index.enumerated().map { "WHEN \(ident(t)).ID = \($0.element) THEN \($0.offset)" }.joined(separator: " ")
      let sql = """
      SELECT Words, Positions, Pointer FROM \(ident(t))
      WHERE ID IN (\(ids))
      ORDER BY CASE \(order) END;
      """
      var stmt: OpaquePointer?
      guard prepare(sql, &stmt) else { return [] }
      defer { sqlite3_finalize(stmt) }
      var results: [PageContent?] = []
      while sqlite3_step(stmt) == SQLITE_ROW {
        guard
          let w = sqlite3_column_text(stmt, 0),
          let p = sqlite3_column_text(stmt, 1),
          let r = sqlite3_column_text(stmt, 2)
        else { results.append(nil); continue }
        let wordsText = String(cString: w)
        let positionsText = String(cString: p)
        let pointerText = String(cString: r)
        let words = wordsText.split(separator: " ").map(String.init)
        let pos = decodePositions(positionsText)              // [[Quadrilateral]]
        let positionsAny: [Any] = pos.map { $0 as Any }       // Adapt to PageContent.positions = [Any]?
        let pointer = decodePointer(pointerText)
        results.append(PageContent(texts: words, positions: positionsAny, pointer: pointer))
      }
      return results
    }
  }

  // MARK: - Encode/Decode
  private func normalizePositionsToString(_ positions: [Any]?) -> String? {
    guard let positions = positions, !positions.isEmpty else { return nil }
    if positions.count == 1, let s = positions.first as? String { return s }
    if let p = positions as? [[Quadrilateral]] { return encodePositions(p) }
    if positions.count == 1, let p = positions.first as? [Quadrilateral] { return encodePositions([p]) }
    if positions.count == 1, let q = positions.first as? Quadrilateral { return encodePositions([[q]]) }
    if positions.count == 1, let r = positions.first as? CGRect { return encodePositions([[quadrilateral(from: r)]]) }
    if let rects = positions as? [CGRect] {
      return encodePositions([rects.map { quadrilateral(from: $0) }])
    }
    var groups: [[Quadrilateral]] = []
    for item in positions {
      if let g = item as? [Quadrilateral] { groups.append(g) }
      else if let q = item as? Quadrilateral { groups.append([q]) }
      else if let r = item as? CGRect { groups.append([quadrilateral(from: r)]) }
      else if let s = item as? String, !s.isEmpty { return s }
      else { return nil }
    }
    return encodePositions(groups)
  }

  private func encodePositions(_ positions: [[Quadrilateral]]) -> String {
    positions.map { arr in
      arr.map { q in
        "{\(q.topLeft.x),\(q.topLeft.y);" +
        "\(q.topRight.x),\(q.topRight.y);" +
        "\(q.bottomRight.x),\(q.bottomRight.y);" +
        "\(q.bottomLeft.x),\(q.bottomLeft.y)}"
      }.joined(separator: "|")
    }.joined(separator: "/")
  }

  private func decodePositions(_ text: String) -> [[Quadrilateral]] {
    guard !text.isEmpty else { return [] }
    return text.split(separator: "/").map { group in
      group.split(separator: "|").compactMap { s in
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.first == "{", t.last == "}" else { return nil }
        let inside = t.dropFirst().dropLast()
        let pts = inside.split(separator: ";").compactMap { pair -> CGPoint? in
          let c = pair.split(separator: ",")
          guard c.count == 2, let x = Double(c[0]), let y = Double(c[1]) else { return nil }
          return CGPoint(x: x, y: y)
        }
        guard pts.count == 4 else { return nil }
        return Quadrilateral(topLeft: pts[0], topRight: pts[1], bottomRight: pts[2], bottomLeft: pts[3])
      }
    }
  }

  private func encodePointer(_ pointer: Pointer) -> String {
    let phrase = pointer.phrasePointer.map { r in r.map { "\($0.lowerBound)-\($0.upperBound)" } ?? "nil" }.joined(separator: ",")
    let sent   = pointer.sentencePointer.map { r in r.map { "\($0.lowerBound)-\($0.upperBound)" } ?? "nil" }.joined(separator: ",")
    return "\(phrase)|\(sent)"
  }

  private func decodePointer(_ text: String) -> Pointer {
    let parts = text.split(separator: "|", omittingEmptySubsequences: false)
    let phrase = parts.indices.contains(0) ? decodeRanges(from: String(parts[0])) : []
    let sent   = parts.indices.contains(1) ? decodeRanges(from: String(parts[1])) : []
    return Pointer(phrasePointer: phrase, sentencePointer: sent)
  }

  private func decodeRanges(from text: String) -> [Range<Int>?] {
    guard !text.isEmpty else { return [] }
    return text.split(separator: ",", omittingEmptySubsequences: false).map { token in
      if token == "nil" { return nil }
      let b = token.split(separator: "-")
      if b.count == 2, let lo = Int(b[0]), let hi = Int(b[1]) { return lo..<hi }
      return nil
    }
  }

  private func encodeCrop(_ crop: Any) -> String {
    if let s = crop as? String { return s }
    if let rect = crop as? CGRect { return encodePositions([[quadrilateral(from: rect)]]) }
    if let rects = crop as? [CGRect] { return encodePositions([rects.map { quadrilateral(from: $0) }]) }
    if let q = crop as? Quadrilateral { return encodePositions([[q]]) }
    if let qs = crop as? [Quadrilateral] { return encodePositions([qs]) }
    if let qss = crop as? [[Quadrilateral]] { return encodePositions(qss) }
    return String(describing: crop)
  }

  private func quadrilateral(from rect: CGRect) -> Quadrilateral {
    Quadrilateral(
      topLeft: CGPoint(x: rect.minX, y: rect.minY),
      topRight: CGPoint(x: rect.maxX, y: rect.minY),
      bottomRight: CGPoint(x: rect.maxX, y: rect.maxY),
      bottomLeft: CGPoint(x: rect.minX, y: rect.maxY)
    )
  }

  private func resolveTargetId(table: String, index: Any?) -> Int? {
    if let i = index as? Int { return i }
    if index == nil {
      var stmt: OpaquePointer?
      let sql = "SELECT MAX(ID) FROM \(ident(table));"
      guard prepare(sql, &stmt) else { return nil }
      defer { sqlite3_finalize(stmt) }
      if sqlite3_step(stmt) == SQLITE_ROW {
        let v = sqlite3_column_int(stmt, 0)
        return (v == 0) ? nil : Int(v)
      }
      return nil
    }
    if let s = index as? String, let i = Int(s) { return i }
    if let n = index as? NSNumber { return n.intValue }
    return nil
  }

  // MARK: - Close
  deinit {
    syncOnDB {
      if db != nil { sqlite3_close(db); db = nil }
    }
  }

  // MARK: - Tiny helper
  public func getType(of value: Any) -> String {
    switch value {
    case is UIImage: return "UIImage"
    case is String:  return "String"
    case is Data:    return "Data"
    case is [Quadrilateral], is [[Quadrilateral]]: return "QuadrilateralArray"
    case is CGRect, is [CGRect]: return "CGRect"
    default: return "Unknown"
    }
  }
}
