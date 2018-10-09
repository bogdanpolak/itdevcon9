# Clean Code in Delphi

**Summary**

> We all know that the quality of the code has a huge impact on the quality of the project. However, it is difficult to meet two programmers who write the code in a similar way. Uncle Bob (Robert C. Martin) has an interesting approach to this topic and his books are widely recognized as the best guides in this area. During this session, Bogdan will show how to apply uncle Bob's principles in practice. Which ones suit the specificity of component and event based programming in Delphi. You will see mostly the same code.


### Motto

Clean code:

* is obvious for other programmers
* doesn't contain duplication
* is easier and cheaper to maintain

### CC in Delphi

1. Build and use **Naming Convention**
    * See sample [naming convention](./NamingConvetion.md)
    * Define it together
    * Maintain it and follow the rules
    * Use it during code reviews
    * Should be common and one for the whole team

2. Use Git as repository server
    * Subversion is more difficult to maintain and slower
    * It's easy to migrate history from SVN to Git
    * Commit you work often
    * Use meaningful commit messages to explain changes 

3. Define code **Code Style Convention** (code format)
    * Use code formatter often
    * Define common company formatter settings and make it easy accessible for each team member
    * Or maybe the best choice is to use default Embarcadero's settings
    * Define pre-commit hook to format code automatically or reject commit with unformatted code

4. Zero Warnings Tolerance
    * Clean all warnings
    * Sometimes it's stupid, but worth
    * If remove all of them quickly isn't possible then define task for the whole team to remove some everyday (you will need some analytics to track improvement)

5. Friday Code Refactoring
    * Arrange weekly - Friday evenings are very common to choose
    * Start *Friday Code Refactoring* with code reviews
    * Good code reviews shouldn't be offensive and rules should be useful.
    * If someone disagree don't push them, but try to understand and then adjust the rules to it.


### Code Bed smells

* Dead code
* Speculative Generality - no need “what if?”
* Large classes
* God object
* Multiple languages in one file
* Framework core modifications
* Magic numbers - replace with const or var
* Long if conditions - replace with function
* Call super’s overwritten methods
* Circular dependency
* Circular references
* Sequential coupling
* Hard-coding
* Too much inheritance - composition is better than inheritance

### Notes

1. [Shubham Gupta - How to write clean code? Lessons learnt from “The Clean Code”](./notes/Mindworks.md)
2. [Clean Code in a nutshell - wojteklu @ GitHubGist](https://gist.github.com/wojteklu/73c6914cc446146b8b533c0988cf8d29)
3. [Clean Code - Robert C. Martin's Way](./notes/DZone.md)
4. [Forget about Clean Code, let’s embrace Compassionate Code](./notes/BiggerBox.md)

### External notes

1. [Codeburst - Write clean code and get rid of code smells with real life examples](https://codeburst.io/write-clean-code-and-get-rid-of-code-smells-aea271f30318)
2. [Hacker Noon - Engineers Don’t Want Clean Code](https://hackernoon.com/engineers-dont-want-clean-code-2dd64cc361c1)
