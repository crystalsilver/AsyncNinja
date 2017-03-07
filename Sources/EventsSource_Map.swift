//
//  Copyright (c) 2016-2017 Anton Mironov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom
//  the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import Dispatch

// MARK: - whole channel transformations
public extension EventsSource {

  /// Applies transformation to the whole channel. `map` methods
  /// are more convenient if you want to transform updates values only.
  ///
  /// - Parameters:
  ///   - context: `ExectionContext` to apply transformation in
  ///   - executor: override of `ExecutionContext`s executor.
  ///     Keep default value of the argument unless you need to override
  ///     an executor provided by the context
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned channel
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply
  ///   - strongContext: context restored from weak reference to specified context
  ///   - value: `ChannelValue` to transform. May be either update or completion
  /// - Returns: transformed channel
    func mapEvent<P, S, C: ExecutionContext>(
        context: C,
        executor: Executor? = nil,
        cancellationToken: CancellationToken? = nil,
        bufferSize: DerivedChannelBufferSize = .default,
        _ transform: @escaping (_ strongContext: C, _ event: Event) throws -> ChannelEvent<P, S>
        ) -> Channel<P, S> {
        return self.makeProducer(context: context,
                                 executor: executor,
                                 cancellationToken: cancellationToken,
                                 bufferSize: bufferSize)
        {
            (context, event, producer, originalExecutor) in
            let transformedEvent = try transform(context, event)
            producer.apply(transformedEvent, from: originalExecutor)
        }
    }

  /// Applies transformation to the whole channel. `map` methods
  /// are more convenient if you want to transform updates values only.
  ///
  /// - Parameters:
  ///   - executor: to execute transform on
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned channel
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply
  ///   - value: `ChannelValue` to transform. May be either update or completion
  /// - Returns: transformed channel
  func mapEvent<P, S>(
    executor: Executor = .primary,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ event: Event) throws -> ChannelEvent<P, S>
    ) -> Channel<P, S> {
    return self.makeProducer(executor: executor,
                             cancellationToken: cancellationToken,
                             bufferSize: bufferSize)
    {
      (event, producer, originalExecutor) in
      let transformedEvent = try transform(event)
      producer.apply(transformedEvent, from: originalExecutor)
    }
  }
}

// MARK: - updates only transformations

public extension EventsSource {

  /// Applies transformation to update values of the channel.
  /// `map` methods are more convenient if you want to transform
  /// both updates and completion
  ///
  /// - Parameters:
  ///   - context: `ExectionContext` to apply transformation in
  ///   - executor: override of `ExecutionContext`s executor.
  ///     Keep default value of the argument unless you need to override
  ///     an executor provided by the context
  ///   - cancellationToken: `CancellationToken` to use. Keep default value
  ///     of the argument unless you need an extended cancellation options
  ///     of the returned channel
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply
  ///   - strongContext: context restored from weak reference to specified context
  ///   - update: `Update` to transform
  /// - Returns: transformed channel
  func map<P, C: ExecutionContext>(
    context: C,
    executor: Executor? = nil,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ strongContext: C, _ update: Update) throws -> P
    ) -> Channel<P, Success> {
    return self.makeProducer(context: context,
                             executor: executor,
                             cancellationToken: cancellationToken,
                             bufferSize: bufferSize)
    {
      (context, value, producer, originalExecutor) in
      switch value {
      case .update(let update):
        let transformedValue = try transform(context, update)
        producer.update(transformedValue, from: originalExecutor)
      case .completion(let completion):
        producer.complete(completion, from: originalExecutor)
      }
    }
  }

  /// Applies transformation to update values of the channel.
  /// `map` methods are more convenient if you want to transform
  /// both updates and completion
  ///
  /// - Parameters:
  ///   - executor: to execute transform on
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned channel
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply
  ///   - update: `Update` to transform
  /// - Returns: transformed channel
  func map<P>(
    executor: Executor = .primary,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ update: Update) throws -> P
    ) -> Channel<P, Success> {

    // Test: Channel_MapTests.testMap

    return self.makeProducer(executor: executor,
                             cancellationToken: cancellationToken,
                             bufferSize: bufferSize)
    {
      (value, producer, originalExecutor) in
      switch value {
      case .update(let update):
        let transformedValue = try transform(update)
        producer.update(transformedValue, from: originalExecutor)
      case .completion(let completion):
        producer.complete(completion, from: originalExecutor)
      }
    }
  }
}

// MARK: - updates only flattening transformations

public extension EventsSource {

  /// Applies transformation to update values of the channel.
  ///
  /// - Parameters:
  ///   - context: `ExectionContext` to apply transformation in
  ///   - executor: override of `ExecutionContext`s executor.
  ///     Keep default value of the argument unless you need to override
  ///     an executor provided by the context
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned channel
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply. Nil returned from transform will not produce update value
  ///   - strongContext: context restored from weak reference to specified context
  ///   - update: `Update` to transform
  /// - Returns: transformed channel
  func flatMap<P, C: ExecutionContext>(
    context: C,
    executor: Executor? = nil,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ strongContext: C, _ update: Update) throws -> P?
    ) -> Channel<P, Success> {
    return self.makeProducer(context: context,
                             executor: executor,
                             cancellationToken: cancellationToken,
                             bufferSize: bufferSize)
    {
      (context, value, producer, originalExecutor) in
      switch value {
      case .update(let update):
        if let transformedValue = try transform(context, update) {
          producer.update(transformedValue, from: originalExecutor)
        }
      case .completion(let completion):
        producer.complete(completion, from: originalExecutor)
      }
    }
  }

  /// Applies transformation to update values of the channel.
  ///
  /// - Parameters:
  ///   - executor: to execute transform on
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned channel
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply. Nil returned from transform will not produce update value
  ///   - update: `Update` to transform
  /// - Returns: transformed channel
  func flatMap<P>(
    executor: Executor = .primary,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ update: Update) throws -> P?
    ) -> Channel<P, Success> {
    return self.makeProducer(executor: executor,
                             cancellationToken: cancellationToken,
                             bufferSize: bufferSize)
    {
      (value, producer, originalExecutor) in
      switch value {
      case .update(let update):
        if let transformedValue = try transform(update) {
          producer.update(transformedValue, from: originalExecutor)
        }
      case .completion(let completion):
        producer.complete(completion, from: originalExecutor)
      }
    }
  }

  /// Applies transformation to update values of the channel.
  ///
  /// - Parameters:
  ///   - context: `ExectionContext` to apply transformation in
  ///   - executor: override of `ExecutionContext`s executor.
  ///     Keep default value of the argument unless you need
  ///     to override an executor provided by the context
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned channel
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply. Sequence returned from transform
  ///     will be treated as multiple period values
  ///   - strongContext: context restored from weak reference to specified context
  ///   - update: `Update` to transform
  /// - Returns: transformed channel
  func flatMap<PS: Sequence, C: ExecutionContext>(
    context: C,
    executor: Executor? = nil,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ strongContext: C, _ update: Update) throws -> PS
    ) -> Channel<PS.Iterator.Element, Success> {
    return self.makeProducer(context: context,
                             executor: executor,
                             cancellationToken: cancellationToken,
                             bufferSize: bufferSize)
    {
      (context, value, producer, originalExecutor) in
      switch value {
      case .update(let update):
        producer.update(try transform(context, update), from: originalExecutor)
      case .completion(let completion):
        producer.complete(completion, from: originalExecutor)
      }
    }
  }

  /// Applies transformation to update values of the channel.
  ///
  /// - Parameters:
  ///   - executor: to execute transform on
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned channel
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - transform: to apply. Sequence returned from transform
  ///     will be treated as multiple period values
  ///   - update: `Update` to transform
  /// - Returns: transformed channel
  func flatMap<PS: Sequence>(
    executor: Executor = .primary,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ transform: @escaping (_ update: Update) throws -> PS
    ) -> Channel<PS.Iterator.Element, Success> {
    return self.makeProducer(executor: executor,
                             cancellationToken: cancellationToken,
                             bufferSize: bufferSize)
    {
      (value, producer, originalExecutor) in
      switch value {
      case .update(let update):
        producer.update(try transform(update), from: originalExecutor)
      case .completion(let completion):
        producer.complete(completion, from: originalExecutor)
      }
    }
  }
}

// MARK: convenient transformations

public extension EventsSource {

  /// Filters update values of the channel
  ///
  ///   - context: `ExectionContext` to apply predicate in
  ///   - executor: override of `ExecutionContext`s executor. Keep default value of the argument unless you need to override an executor provided by the context
  ///   - cancellationToken: `CancellationToken` to use. Keep default value of the argument unless you need an extended cancellation options of returned channel
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel. Keep default value of the argument unless you need an extended buffering options of returned channel
  ///   - predicate: to apply
  ///   - strongContext: context restored from weak reference to specified context
  ///   - update: `Update` to transform
  /// - Returns: filtered transform
  func filter<C: ExecutionContext>(
    context: C,
    executor: Executor? = nil,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ predicate: @escaping (_ strongContext: C, _ update: Update) throws -> Bool
    ) -> Channel<Update, Success> {
    return self.makeProducer(context: context,
                             executor: executor,
                             cancellationToken: cancellationToken,
                             bufferSize: bufferSize)
    {
      (context, value, producer, originalExecutor) in
      switch value {
      case .update(let update):
        do {
          if try predicate(context, update) {
            producer.update(update, from: originalExecutor)
          }
        } catch { producer.fail(error, from: originalExecutor) }
      case .completion(let completion):
        producer.complete(completion, from: originalExecutor)
      }
    }
  }

  /// Filters update values of the channel
  ///
  ///   - executor: to execute transform on
  ///   - cancellationToken: `CancellationToken` to use.
  ///     Keep default value of the argument unless you need
  ///     an extended cancellation options of returned channel
  ///   - bufferSize: `DerivedChannelBufferSize` of derived channel.
  ///     Keep default value of the argument unless you need
  ///     an extended buffering options of returned channel
  ///   - predicate: to apply
  ///   - update: `Update` to transform
  /// - Returns: filtered transform
  func filter(
    executor: Executor = .primary,
    cancellationToken: CancellationToken? = nil,
    bufferSize: DerivedChannelBufferSize = .default,
    _ predicate: @escaping (_ update: Update) throws -> Bool
    ) -> Channel<Update, Success> {

    // Test: Channel_MapTests.testFilterUpdate

    return self.makeProducer(executor: executor,
                             cancellationToken: cancellationToken,
                             bufferSize: bufferSize)
    {
      (value, producer, originalExecutor) in
      switch value {
      case .update(let update):
        do {
          if try predicate(update) {
            producer.update(update, from: originalExecutor)
          }
        } catch { producer.fail(error, from: originalExecutor) }
      case .completion(let completion):
        producer.complete(completion, from: originalExecutor)
      }
    }
  }
}

public extension EventsSource where Update: _Fallible {
  /// makes channel of unsafely unwrapped optional Updates
  var unsafelyUnwrapped: Channel<Update.Success, Success> {
    return map(executor: .immediate) { $0.unsafeSuccess }
  }

  /// makes channel of unsafely unwrapped optional Updates
  var unwrapped: Channel<Update.Success, Success> {
    return map(executor: .immediate) {
      if let success = $0.success {
        return success
      } else if let failure = $0.failure {
        throw failure
      } else {
        fatalError("callback must return either success or failure")
      }
    }
  }
}