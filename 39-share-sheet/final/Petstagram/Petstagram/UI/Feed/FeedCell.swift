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

import SwiftUI
import Combine

struct FeedCell: View {
  @Binding var post: Post
  let placeholderImage = UIImage(systemName: "photo")!
  @State var postImage: UIImage? = nil
  @State private var showComments = false
  @State private var showShareSheet = false
  @State private var subscriptions: Set<AnyCancellable> = []

  var body: some View {
    VStack {
      Image(uiImage: postImage ?? placeholderImage)
        .resizable()
        .scaledToFit()
        .cornerRadius(15)
        .overlay({
          VStack(spacing: 15) {
            Button(action: toggleLike) {
              Image(post.isLiked ? "like-filled" : "like-empty")
            }
            Button(action: { showComments = true }) {
              Image("comment")
            }
            Button(action: { showShareSheet = true }) {
              Image("share")
            }
            .sheet(isPresented: $showShareSheet) {
              createShareSheet()
            }
          }
          .padding()
          .shadow(radius: 3)
        }(), alignment: .bottomTrailing)
        .onAppear {
          guard let imageId = self.post.id else { return }
          let client = APIClient()
          let request = DownloadImageRequest(imageId: imageId)
          client.publisherForRequest(request)
            .replaceError(with: placeholderImage)
            .sink { image in
              postImage = image
            }
            .store(in: &subscriptions)
        }
      NavigationLink(
        destination: CommentListView(forPostId: post.id ?? UUID(), image: postImage ?? placeholderImage),
        isActive: $showComments) {
        // When rendering the image inside the link, it shows the full width of the screen with a disclosure indicator, even if I try applying a button style. So we fall back to using an empty link with programmatic navigation.
        EmptyView()
      }
      CommentCell(comment: post)
    }
    .buttonStyle(PlainButtonStyle())
  }

  private func createShareSheet() -> ShareSheet {
    var items: [Any] = []
    if let image = postImage {
      items.append(image)
    }
    if post.caption.isEmpty == false {
      items.append(post.caption)
    }
    return ShareSheet(activityItems: items)
  }

  private func toggleLike() {
    if post.isLiked {
      deleteLike()
    } else {
      addLike()
    }
  }

  private func addLike() {
    guard let postId = post.id else { fatalError() }
    let client = APIClient()
    let request = AddLikeToPostRequest(postId: postId)
    client.publisherForRequest(request)
      .sink(receiveCompletion: { result in
        if case .finished = result {
          post.isLiked = true
        }
      }, receiveValue: {_ in})
      .store(in: &subscriptions)
  }

  private func deleteLike() {
    guard let postId = post.id else { fatalError() }
    let client = APIClient()
    let request = DeleteLikeFromPostRequest(postId: postId)
    client.publisherForRequest(request)
      .sink(receiveCompletion: { result in
        if case .finished = result {
          post.isLiked = false
        }
      }, receiveValue: {_ in})
      .store(in: &subscriptions)
  }
}

struct FeedCell_Previews: PreviewProvider {
  static var previews: some View {
    let createdDate = Date().advanced(by: TimeInterval(exactly: -5*60)!)
    let post = Post(caption: "Can you code me up some food?", createdAt: createdDate, createdBy: "UserName")
    var likedPost = post
    likedPost.isLiked = true
    return Group {
      NavigationView {
        FeedCell(post: .constant(post))
          .previewDisplayName("Placeholder Image")
      }
      NavigationView {
        FeedCell(post: .constant(post), postImage: UIImage(named: "friends")!)
          .previewDisplayName("Unliked Post with Image")
      }
      NavigationView {
        FeedCell(post: .constant(likedPost), postImage: UIImage(named: "friends")!)
          .previewDisplayName("Liked Post with Image")
      }
    }
    .previewLayout(.sizeThatFits)
  }
}
