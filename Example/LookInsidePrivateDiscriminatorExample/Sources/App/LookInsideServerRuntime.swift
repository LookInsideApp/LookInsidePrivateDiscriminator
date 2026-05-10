#if canImport(LookInsideServer)
    import LookInsideServer
#endif

enum LookInsideServerRuntime {
    static var isLicensed: Bool {
        #if canImport(LookInsideServer)
            LookInsideServer.isLicensed
        #else
            false
        #endif
    }
}
