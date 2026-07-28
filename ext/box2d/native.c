#if defined(_WIN32)
#define BOX2D_RUBY_EXPORT __declspec(dllexport)
#else
#define BOX2D_RUBY_EXPORT __attribute__((visibility("default")))
#endif

BOX2D_RUBY_EXPORT void Init_native(void)
{
}
