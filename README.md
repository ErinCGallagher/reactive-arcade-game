# reactive-arcade-game
An Introduction to Reactive programming using RxSwift.

To follow along during the workshop, ensure to have completed the <b>SETUP</b> instructions in advance.

## File Structure

### MyPlayground.playground
- The playground file used to build the arcade game

### ReactiveArcadeGame.xcworkspace
- The workspace file with RxCocoa & RxSwift installed 
- <code>ReactiveArcadePlayground</code> exists within this workspace and that is required for RxSwift playground support

## Branching Structure

### master
- Default Bracnch
- branch with worklshop tasks 1 - 3 not completed, find <code> // TODO: </code> in the code
- Use this branch as a starting point when working through the workshop

### workshop-solution
- Branch with the completed solutions to workshop tasks 1 - 3

## Setup
1. Download Xcode: https://apps.apple.com/ca/app/xcode/id497799835?mt=12
    - This step could take a while, please do this before the workshop
    
2. clone or download this repository
    - Look for the green <i> Clone or Download</i> button at the top right of the screen
    
3. Download & install the required pods (libraries) for RxSwift & RxCocoa
    
    i)  open the terminal
    
    ii) navigate to <code>ReactiveArcadeGame</code> Folder
    
    ii) run the following command in the terminal: <code> pod install </code>
    
    iii) run the following command in the terminal: <code> pod update </code>
    
    - cocoa pods will need to be installed for these commands to run, see Common Errors #4
    
    
### How to Open the Project?
1. Open the <code>ReactiveArcadeGame.xcworkspace</code> file by selecting it
   - Xcode should open the selected file
   
2. From the left panel, select the <code>MyPlayground</Code> file

## Common Errors

1. Missing RxSwift & RxCocoa

    i) Product -> Clean Build Folder (shift + cmd + k)

   ii) Product -> Build (cmd + b)

   iii) Restart Xcode

    <pre><code>
    Playground execution failed:

    error: MyPlayground.playground:5:8: error: no such module 'RxSwift'
    import RxSwift
           ^

    error: MyPlayground.playground:6:8: error: no such module 'RxCocoa'
    import RxCocoa
           ^
    </code></pre>

2. "Runnig MyPlayground" continuously loads and never succeeds

    i) Same solution as #1
    
3. Could not look up symbols

    i) Same solution as #1
    
<pre><code>
Playground execution failed:

error: Couldn't lookup symbols:
  RxCocoa.BehaviorRelay.asObservable() -> RxSwift.Observable<A>
  RxCocoa.BehaviorRelay.asObservable() -> RxSwift.Observable<A>
</code></pre>
    
4. Cocoa pods not installed

    i) run this command in the terminal <code> sudo gem install cocoapods </code>

    <code>-bash: pod: command not found</code>
