# Dependency Injection

Serinus handles the dependency injection using the `Context`s and `Module`s. Every module has a context that contains all its own providers, the providers from the imported modules, the global providers and the parent context.

This means that if a provider is defined in the parent module, it will be available in its children modules. But if a provider is imported in a module, it will not be available in the parent module.