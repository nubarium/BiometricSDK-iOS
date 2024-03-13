#  <#Title#>

Agregar  timeouts



        
        // –––––– Resource-specific configuration ––––––
        service.configure("/search/**") {
            // Refresh search results after 10 seconds (Siesta default is 30)
            $0.expirationTime = 10
        }
        
        // –––––– Mapping from specific paths to models ––––––
        // These all use Swift 4’s JSONDecoder, but you can configure arbitrary transforms on arbitrary data types.
        service.configureTransformer("/users/*") {
            // Input type inferred because the from: param takes Data.
            // Output type inferred because jsonDecoder.decode() will return User
            try jsonDecoder.decode(User.self, from: $0.content)
        }
        
        service.configureTransformer("/users/*/repos") {
            try jsonDecoder.decode([Repository].self, from: $0.content)
        }
        
        service.configureTransformer("/search/repositories") {
            try jsonDecoder.decode(SearchResults<Repository>.self, from: $0.content)
                .items  // Transformers can do arbitrary post-processing
        }
        
        service.configureTransformer("/repos/*/*") {
            try jsonDecoder.decode(Repository.self, from: $0.content)
        }
        
        service.configureTransformer("/repos/*/*/contributors") {
            try jsonDecoder.decode([User].self, from: $0.content)
        }
        
        service.configureTransformer("/repos/*/*/languages") {
            // For this request, GitHub gives a response of the form {"Swift": 421956, "Objective-C": 11000, ...}.
            // Instead of using a custom model class for this one, we just model it as a raw dictionary.
            try jsonDecoder.decode([String:Int].self, from: $0.content)
        }
        
        service.configure("/user/starred/*/*") {   // GitHub gives 202 for “starred” and 404 for “not starred.”
            $0.pipeline[.model].add(               // This custom transformer turns that curious convention into
                TrueIfResourceFoundTransformer())  // a resource whose content is a simple boolean.
        }









    
    func user(_ username: String) -> Resource {
        return service
            .resource("/users")
            .child(username.lowercased())
    }
    
    func repository(ownedBy login: String, named name: String) -> Resource {
        return service
            .resource("/repos")
            .child(login)
            .child(name)
    }
    
    func repository(_ repositoryModel: Repository) -> Resource {
        return repository(
            ownedBy: repositoryModel.owner.login,
            named: repositoryModel.name)
    }
    
    func currentUserStarred(_ repositoryModel: Repository) -> Resource {
        return service
            .resource("/user/starred")
            .child(repositoryModel.owner.login)
            .child(repositoryModel.name)
    }
    
    func setStarred(_ isStarred: Bool, repository repositoryModel: Repository) -> Request {
        let starredResource = currentUserStarred(repositoryModel)
        return starredResource
            .request(isStarred ? .put : .delete)
            .onSuccess { _ in
                // Update succeeded. Directly update the locally cached “starred / not starred” state.
                starredResource.overrideLocalContent(with: isStarred)
                
                // Ask server for an updated star count. Note that we only need to trigger the load here, not handle
                // the response! Any UI that is displaying the star count will be observing this resource, and thus
                // will pick up the change. The code that knows _when_ to trigger the load is decoupled from the code
                // that knows _what_ to do with the updated data. This is the magic of Siesta.
                for delay in [0.1, 1.0, 2.0] {  // Github propagates the updated star count slowly
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        // This ham-handed repeated loading is not as expensive as it first appears, thanks to the fact
                        // that Siesta magically takes care of ETag / If-modified-since / HTTP 304 for us.
                        self.repository(repositoryModel).load()
                    }
                }
            }
    }
