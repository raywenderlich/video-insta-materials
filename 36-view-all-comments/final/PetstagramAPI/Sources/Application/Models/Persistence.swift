/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import SwiftKueryORM
import SwiftKueryPostgreSQL
import LoggerAPI

extension Post: Model { }
extension UserAuthentication: Model { }
extension Like: Model { }
extension Comment: Model { }

class Persistence {
  static func setUp() {
    let pool = PostgreSQLConnection.createPool(
      host: ProcessInfo.processInfo.environment["DBHOST"] ?? "localhost",
      port: 5432,
      options: [.databaseName("petstagram"),
                .userName(ProcessInfo.processInfo.environment["DBUSER"] ?? "postgres"),
                .password(ProcessInfo.processInfo.environment["DBPASSWORD"] ?? "nil")
      ],
      poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50)
    )
    Database.default = Database(pool)

    createTable(Post.self)
    createTable(UserAuthentication.self)
    createTable(Like.self)
    createTable(Comment.self)
  }

  private static func createTable<T: Model>(_ Table: T.Type) {
//    _ = try? Table.dropTableSync()
    do {
      try Table.createTableSync()
    } catch let tableError {
      if let requestError = tableError as? RequestError,
         requestError.rawValue == RequestError.ormQueryError.rawValue {
        Log.info("Table \(Table.tableName) already exists")
      } else {
        Log.error("Database connection error: \(String(describing: tableError))")
      }
    }
  }
}
