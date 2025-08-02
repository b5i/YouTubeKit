//
//  YTComment+actions.swift
//  
//
//  Created by Antoine Bollengier on 03.07.2024.
//  Copyright © 2024 - 2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

public extension YTComment {
    /// Do one of the ``YTComment/CommentAction`` (like, dislike, removeLike, removeDislike, delete).
    func commentAction(youtubeModel: YouTubeModel, action: YTComment.CommentAction, result: @escaping @Sendable (Error?) -> Void) {
        switch action {
        case .like:
            guard let param = self.actionsParams[.like] else { result("self.actionsParams[.like] is not present."); return }
            LikeCommentResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.params: param], result: { res in
                switch res {
                case .success(_):
                    result(nil)
                case .failure(let failure):
                    result(failure)
                }
            })
        case .dislike:
            guard let param = self.actionsParams[.dislike] else { result("self.actionsParams[.dislike] is not present."); return }
            DislikeCommentResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.params: param], result: { res in
                switch res {
                case .success(_):
                    result(nil)
                case .failure(let failure):
                    result(failure)
                }
            })
        case .removeLike:
            guard let param = self.actionsParams[.removeLike] else { result("self.actionsParams[.removeLike] is not present."); return }
            RemoveLikeCommentResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.params: param], result: { res in
                switch res {
                case .success(_):
                    result(nil)
                case .failure(let failure):
                    result(failure)
                }
            })
        case .removeDislike:
            guard let param = self.actionsParams[.removeDislike] else { result("self.actionsParams[.removeDislike] is not present."); return }
            RemoveDislikeCommentResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.params: param], result: { res in
                switch res {
                case .success(_):
                    result(nil)
                case .failure(let failure):
                    result(failure)
                }
            })
        case .delete:
            guard let param = self.actionsParams[.delete] else { result("self.actionsParams[.delete] is not present."); return }
            DeleteCommentResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.params: param], result: { res in
                switch res {
                case .success(_):
                    result(nil)
                case .failure(let failure):
                    result(failure)
                }
            })
        case .edit:
            result("edit is not supported via commentAction(_:_:_:), please use editComment(_:_:).")
        case .reply:
            result("reply is not supported via commentAction(_:_:_:), please use replyToComment(_:_:).")
        case .repliesContinuation:
            result("repliesContinuation is not supported via commentAction(_:_:_:), please use fetchRepliesContinuation(_:_:).")
        case .translate:
            result("translate is not supported via commentAction(_:_:_:), please use translateText(_:_:).")
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func commentAction(youtubeModel: YouTubeModel, action: YTComment.CommentAction) async throws {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            self.commentAction(youtubeModel: youtubeModel, action: action, result: { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        })
    }
    
    /// Edit the text of a comment (the cookies from the used ``YouTubeModel`` must be the owner of the comment).
    func editComment(withNewText text: String, youtubeModel: YouTubeModel, result: @escaping @Sendable (Error?) -> Void) {
        guard let param = self.actionsParams[.edit] else { result("self.actionsParams[.edit] is not present."); return }
        if (self.replyLevel ?? 0) == 0 {
            EditCommentResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.params: param, .text: text], result: { res in
                switch res {
                case .success(_):
                    result(nil)
                case .failure(let failure):
                    result(failure)
                }
            })
        } else {
            EditReplyCommandResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.params: param, .text: text], result: { res in
                switch res {
                case .success(_):
                    result(nil)
                case .failure(let failure):
                    result(failure)
                }
            })
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Edit the text of a comment (the cookies from the used ``YouTubeModel`` must be the owner of the comment).
    func editComment(withNewText text: String, youtubeModel: YouTubeModel) async throws {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            self.editComment(withNewText: text, youtubeModel: youtubeModel, result: { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        })
    }
    
    /// Reply to a comment.
    func replyToComment(youtubeModel: YouTubeModel, text: String, result: @escaping @Sendable (Result<ReplyCommentResponse, Error>) -> Void) {
        guard let replyToken = self.actionsParams[.reply] else { result(.failure("self.actionsParams[.reply] is not present.")); return }
        ReplyCommentResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.params: replyToken, .text: text], result: { res in
            switch res {
            case .success(let success):
                result(.success(success))
            case .failure(let failure):
                result(.failure(failure))
            }
        })
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Reply to a comment.
    func replyToComment(youtubeModel: YouTubeModel, text: String) async throws -> ReplyCommentResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<ReplyCommentResponse, Error>) in
            self.replyToComment(youtubeModel: youtubeModel, text: text, result: { response in
                continuation.resume(with: response)
            })
        })
    }
    
    /// Get the replies of a comment, can also be used to get the continuation of the replies.
    func fetchRepliesContinuation(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable (Result<VideoCommentsResponse.Continuation, Error>) -> Void) {
        guard let repliesContinuationToken = self.actionsParams[.repliesContinuation] else { result(.failure("self.actionsParams[.repliesContinuation] is not present.")); return }
        VideoCommentsResponse.Continuation.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.continuation: repliesContinuationToken], useCookies: useCookies, result: { res in
            switch res {
            case .success(let success):
                result(.success(success))
            case .failure(let failure):
                result(.failure(failure))
            }
        })
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Get the replies of a comment, can also be used to get the continuation of the replies.
    func fetchRepliesContinuation(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> VideoCommentsResponse.Continuation {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<VideoCommentsResponse.Continuation, Error>) in
            self.fetchRepliesContinuation(youtubeModel: youtubeModel, useCookies: useCookies, result: { response in
                continuation.resume(with: response)
            })
        })
    }
    
    /// Translate the text of a comment, is available if YouTube thinks that the cookies' user or the language of the user agent (?) might need a translation.
    func translateText(youtubeModel: YouTubeModel, useCookies: Bool? = nil, result: @escaping @Sendable (Result<CommentTranslationResponse, Error>) -> Void) {
        guard let translationToken = self.actionsParams[.translate] else { result(.failure("self.actionsParams[.translate] is not present.")); return }
        CommentTranslationResponse.sendNonThrowingRequest(youtubeModel: youtubeModel, data: [.params: translationToken], useCookies: useCookies, result: { res in
            switch res {
            case .success(let success):
                result(.success(success))
            case .failure(let failure):
                result(.failure(failure))
            }
        })
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Translate the text of a comment, is available if YouTube thinks that the cookies' user or the language of the user agent (?) might need a translation.
    func translateText(youtubeModel: YouTubeModel, useCookies: Bool? = nil) async throws -> CommentTranslationResponse {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<CommentTranslationResponse, Error>) in
            self.translateText(youtubeModel: youtubeModel, useCookies: useCookies, result: { response in
                continuation.resume(with: response)
            })
        })
    }
}
