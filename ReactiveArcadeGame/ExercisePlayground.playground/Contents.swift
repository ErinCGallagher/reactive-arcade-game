import RxSwift

let observableJust = Observable.just("Hello, world!")
observableJust.subscribe({ (event: Event<String>) in
    print(event)
})
observableJust.subscribe(
    onNext: {
        print($0)
    },
    onError: {
        print("onError \($0)")
    },
    onCompleted: {
        print("onCompleted")
    })
observableJust.subscribe(onNext: { text in
    print(text)
})


Observable.of(1, 2, 3)
    .subscribe(onNext: {
        print($0)
    })
