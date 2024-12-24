//
//  RedisManager.swift
//  DateSpot
//
//  Created by 하동훈 on 22/12/2024.
//

import Foundation
import NIO
import RediStack

class RedisManager {
    static let shared = RedisManager()

    private let eventLoopGroup: EventLoopGroup
    private var connection: RedisConnection?

    private init() {
        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        do {
            try connectToRedis()
        } catch {
            print("Redis 연결 중 오류 발생: \(error)")
        }
    }

    deinit {
        do {
            try eventLoopGroup.syncShutdownGracefully()
        } catch {
            print("Failed to shut down Redis EventLoopGroup: \(error)")
        }
    }

    /// Redis에 연결
    private func connectToRedis() throws {
        let configuration = try RedisConnection.Configuration(
            hostname: "datespot-redis.a4ifxd.ng.0001.apn2.cache.amazonaws.com", // Redis 엔드포인트
            port: 6379 // Redis 기본 포트
        )
        
        let connectionFuture = RedisConnection.make(
            configuration: configuration,
            boundEventLoop: eventLoopGroup.next()
        )
        
        // 타임아웃 설정: 30초 후 연결 시도 실패 처리
        let timeoutFuture = connectionFuture.flatMapErrorThrowing { error in
            throw error
        }.flatMap { connection -> EventLoopFuture<RedisConnection> in
            let promise = connection.eventLoop.makePromise(of: RedisConnection.self)
            connection.eventLoop.scheduleTask(in: .seconds(30)) {
                promise.fail(NIOTimeoutError())
            }
            return promise.futureResult
        }

        do {
            self.connection = try timeoutFuture.wait()
            print("Redis 연결 성공")
        } catch {
            print("Redis 연결 중 오류 발생: \(error)")
            throw error
        }
    }
    
    /// Redis에 데이터 저장
    func setValue(key: String, value: String, completion: @escaping (Bool) -> Void) {
        guard let connection = connection else {
            print("Redis 연결 없음")
            completion(false)
            return
        }

        let redisKey = RedisKey(key)
        connection.set(redisKey, to: value).whenComplete { result in
            switch result {
            case .success:
                print("데이터 저장 성공: \(key) -> \(value)")
                completion(true)
            case .failure(let error):
                print("데이터 저장 실패: \(error)")
                completion(false)
            }
        }
    }

    /// Redis에서 데이터 조회
    func getValue(key: String, completion: @escaping (String?) -> Void) {
        guard let connection = connection else {
            print("Redis 연결 없음")
            completion(nil)
            return
        }

        let redisKey = RedisKey(key)
        connection.get(redisKey, as: String.self).whenComplete { result in
            switch result {
            case .success(let value):
                print("데이터 조회 성공: \(key) -> \(value ?? "nil")")
                completion(value)
            case .failure(let error):
                print("데이터 조회 실패: \(error)")
                completion(nil)
            }
        }
    }
    
} // RedisManager.swift

struct NIOTimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "Redis 연결 타임아웃: 서버가 응답하지 않습니다."
    }
}
