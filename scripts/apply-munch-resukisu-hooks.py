#!/usr/bin/env python3
from pathlib import Path


ROOT = Path.cwd()


def replace_once(path, old, new):
    file_path = ROOT / path
    text = file_path.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f"pattern not found in {path}")
    file_path.write_text(text.replace(old, new, 1))


def insert_before(path, marker, snippet):
    file_path = ROOT / path
    text = file_path.read_text()
    if snippet in text:
        return
    if marker not in text:
        raise SystemExit(f"marker not found in {path}")
    file_path.write_text(text.replace(marker, snippet + marker, 1))


insert_before(
    "kernel/sys.c",
    "/*\n * This function implements a generic ability to update ruid, euid,\n",
    """#ifdef CONFIG_KSU_SUSFS
extern int ksu_handle_setresuid(uid_t ruid, uid_t euid, uid_t suid);
#endif

""",
)

replace_once(
    "kernel/sys.c",
    """\tkuid_t kruid, keuid, ksuid;

\tkruid = make_kuid(ns, ruid);
""",
    """\tkuid_t kruid, keuid, ksuid;

#ifdef CONFIG_KSU_SUSFS
\tksu_handle_setresuid(ruid, euid, suid);
#endif

\tkruid = make_kuid(ns, ruid);
""",
)

insert_before(
    "fs/exec.c",
    "int do_execve_file(struct file *file, void *__argv, void *__envp)\n",
    """#ifdef CONFIG_KSU_SUSFS
extern int ksu_handle_execveat(int *fd, struct filename **filename_ptr,
\t\t\t\tvoid *argv, void *envp, int *flags);
#endif

""",
)

replace_once(
    "fs/exec.c",
    """\tstruct user_arg_ptr argv = { .ptr.native = __argv };
\tstruct user_arg_ptr envp = { .ptr.native = __envp };
\treturn do_execveat_common(AT_FDCWD, filename, argv, envp, 0);
}
""",
    """\tstruct user_arg_ptr argv = { .ptr.native = __argv };
\tstruct user_arg_ptr envp = { .ptr.native = __envp };
#ifdef CONFIG_KSU_SUSFS
\tint ksu_fd = AT_FDCWD;
\tint ksu_flags = 0;
\tksu_handle_execveat(&ksu_fd, &filename, &argv, &envp, &ksu_flags);
\treturn do_execveat_common(ksu_fd, filename, argv, envp, ksu_flags);
#else
\treturn do_execveat_common(AT_FDCWD, filename, argv, envp, 0);
#endif
}
""",
)

replace_once(
    "fs/exec.c",
    """\tstruct user_arg_ptr argv = { .ptr.native = __argv };
\tstruct user_arg_ptr envp = { .ptr.native = __envp };

\treturn do_execveat_common(fd, filename, argv, envp, flags);
}
""",
    """\tstruct user_arg_ptr argv = { .ptr.native = __argv };
\tstruct user_arg_ptr envp = { .ptr.native = __envp };

#ifdef CONFIG_KSU_SUSFS
\tksu_handle_execveat(&fd, &filename, &argv, &envp, &flags);
#endif
\treturn do_execveat_common(fd, filename, argv, envp, flags);
}
""",
)

replace_once(
    "fs/exec.c",
    """\tstruct user_arg_ptr envp = {
\t\t.is_compat = true,
\t\t.ptr.compat = __envp,
\t};
\treturn do_execveat_common(AT_FDCWD, filename, argv, envp, 0);
}
""",
    """\tstruct user_arg_ptr envp = {
\t\t.is_compat = true,
\t\t.ptr.compat = __envp,
\t};
#ifdef CONFIG_KSU_SUSFS
\tint ksu_fd = AT_FDCWD;
\tint ksu_flags = 0;
\tksu_handle_execveat(&ksu_fd, &filename, &argv, &envp, &ksu_flags);
\treturn do_execveat_common(ksu_fd, filename, argv, envp, ksu_flags);
#else
\treturn do_execveat_common(AT_FDCWD, filename, argv, envp, 0);
#endif
}
""",
)

replace_once(
    "fs/exec.c",
    """\tstruct user_arg_ptr envp = {
\t\t.is_compat = true,
\t\t.ptr.compat = __envp,
\t};
\treturn do_execveat_common(fd, filename, argv, envp, flags);
}
""",
    """\tstruct user_arg_ptr envp = {
\t\t.is_compat = true,
\t\t.ptr.compat = __envp,
\t};
#ifdef CONFIG_KSU_SUSFS
\tksu_handle_execveat(&fd, &filename, &argv, &envp, &flags);
#endif
\treturn do_execveat_common(fd, filename, argv, envp, flags);
}
""",
)

insert_before(
    "fs/open.c",
    "SYSCALL_DEFINE3(faccessat, int, dfd, const char __user *, filename, int, mode)\n",
    """#ifdef CONFIG_KSU_SUSFS
extern int ksu_handle_faccessat(int *dfd, const char __user **filename_user,
\t\t\t\tint *mode, int *flags);
#endif

""",
)

replace_once(
    "fs/open.c",
    """SYSCALL_DEFINE3(faccessat, int, dfd, const char __user *, filename, int, mode)
{
\treturn do_faccessat(dfd, filename, mode);
}
""",
    """SYSCALL_DEFINE3(faccessat, int, dfd, const char __user *, filename, int, mode)
{
#ifdef CONFIG_KSU_SUSFS
\tksu_handle_faccessat(&dfd, &filename, &mode, NULL);
#endif
\treturn do_faccessat(dfd, filename, mode);
}
""",
)

insert_before(
    "fs/read_write.c",
    "SYSCALL_DEFINE3(read, unsigned int, fd, char __user *, buf, size_t, count)\n",
    """#ifdef CONFIG_KSU_SUSFS
extern int ksu_handle_sys_read(unsigned int fd, char __user **buf_ptr, size_t *count_ptr);
#endif

""",
)

replace_once(
    "fs/read_write.c",
    """SYSCALL_DEFINE3(read, unsigned int, fd, char __user *, buf, size_t, count)
{
\treturn ksys_read(fd, buf, count);
}
""",
    """SYSCALL_DEFINE3(read, unsigned int, fd, char __user *, buf, size_t, count)
{
#ifdef CONFIG_KSU_SUSFS
\tksu_handle_sys_read(fd, &buf, &count);
#endif
\treturn ksys_read(fd, buf, count);
}
""",
)

insert_before(
    "fs/stat.c",
    "#include <linux/uaccess.h>\n",
    """#ifdef CONFIG_KSU_SUSFS
extern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);
extern void ksu_handle_newfstat_ret(unsigned int *fd, struct stat __user **statbuf_ptr);
extern void ksu_handle_fstat64_ret(unsigned long *fd, struct stat64 __user **statbuf_ptr);
#endif

""",
)

replace_once(
    "fs/stat.c",
    """\tstruct kstat stat;
\tint error;

\terror = vfs_fstatat(dfd, filename, &stat, flag);
""",
    """\tstruct kstat stat;
\tint error;

#ifdef CONFIG_KSU_SUSFS
\tksu_handle_stat(&dfd, &filename, &flag);
#endif
\terror = vfs_fstatat(dfd, filename, &stat, flag);
""",
)

replace_once(
    "fs/stat.c",
    """\tif (!error)
\t\terror = cp_new_stat(&stat, statbuf);

\treturn error;
}
""",
    """\tif (!error)
\t\terror = cp_new_stat(&stat, statbuf);
#ifdef CONFIG_KSU_SUSFS
\tksu_handle_newfstat_ret(&fd, &statbuf);
#endif
\treturn error;
}
""",
)

replace_once(
    "fs/stat.c",
    """\tif (!error)
\t\terror = cp_new_stat64(&stat, statbuf);

\treturn error;
}

SYSCALL_DEFINE4(fstatat64, int, dfd, const char __user *, filename,
""",
    """\tif (!error)
\t\terror = cp_new_stat64(&stat, statbuf);
#ifdef CONFIG_KSU_SUSFS
\tksu_handle_fstat64_ret(&fd, &statbuf);
#endif
\treturn error;
}

SYSCALL_DEFINE4(fstatat64, int, dfd, const char __user *, filename,
""",
)

replace_once(
    "fs/stat.c",
    """SYSCALL_DEFINE4(fstatat64, int, dfd, const char __user *, filename,
\t\tstruct stat64 __user *, statbuf, int, flag)
{
\tstruct kstat stat;
\tint error;

\terror = vfs_fstatat(dfd, filename, &stat, flag);
""",
    """SYSCALL_DEFINE4(fstatat64, int, dfd, const char __user *, filename,
\t\tstruct stat64 __user *, statbuf, int, flag)
{
\tstruct kstat stat;
\tint error;

#ifdef CONFIG_KSU_SUSFS
\tksu_handle_stat(&dfd, &filename, &flag);
#endif
\terror = vfs_fstatat(dfd, filename, &stat, flag);
""",
)

insert_before(
    "kernel/reboot.c",
    "SYSCALL_DEFINE4(reboot, int, magic1, int, magic2, unsigned int, cmd,\n",
    """#ifdef CONFIG_KSU_SUSFS
extern int ksu_handle_sys_reboot(int magic1, int magic2, unsigned int cmd, void __user **arg);
#endif

""",
)

replace_once(
    "kernel/reboot.c",
    """\tchar buffer[256];
\tint ret = 0;

\tif (check_poweroff_charger_mode()){
""",
    """\tchar buffer[256];
\tint ret = 0;

#ifdef CONFIG_KSU_SUSFS
\tksu_handle_sys_reboot(magic1, magic2, cmd, &arg);
#endif

\tif (check_poweroff_charger_mode()){
""",
)

insert_before(
    "drivers/input/input.c",
    "void input_event(struct input_dev *dev,\n",
    """#ifdef CONFIG_KSU_SUSFS
extern int ksu_handle_input_handle_event(unsigned int *type, unsigned int *code, int *value);
#endif

""",
)

replace_once(
    "drivers/input/input.c",
    """\tif (is_event_supported(type, dev->evbit, EV_MAX)) {

\t\tspin_lock_irqsave(&dev->event_lock, flags);
""",
    """\tif (is_event_supported(type, dev->evbit, EV_MAX)) {

#ifdef CONFIG_KSU_SUSFS
\t\tksu_handle_input_handle_event(&type, &code, &value);
#endif
\t\tspin_lock_irqsave(&dev->event_lock, flags);
""",
)
