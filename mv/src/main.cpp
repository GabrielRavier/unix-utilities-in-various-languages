#include <system_error>
#include <vector>
#include <string_view>
#include <string>
#include <optional>
#include <iostream>
#include <filesystem>
#include <fmt/format.h>
#include <unistd.h>
#include <sys/wait.h>
#include <assert.h>

struct mv_options {
    bool i_flag = false;
    bool f_flag = false;
};

static std::string g_argv0;

template<typename ...T>
static void print_error(fmt::format_string<T...> fmt, T&&... args)
{
    std::cerr << fmt::format("{}: ", g_argv0) << fmt::format(fmt, args...) << '\n';
}

template<typename ...T>
[[noreturn]] static void print_error_and_die(fmt::format_string<T...> fmt, T&&... args)
{
    print_error(fmt, args...);
    std::exit(EXIT_FAILURE);
}

static std::string_view get_basename(std::string_view filename)
{
    while (filename.size() != 0 && filename.front() == '/')
        filename = {&filename[1], filename.end()};

    bool last_saw_slash = false;
    for (std::string_view i = filename; i.size() != 0; i = {&i[1], i.end()})
        if (i.front() == '/')
            last_saw_slash = true;
        else if (last_saw_slash) {
            filename = i;
            last_saw_slash = false;
        }
    return filename;
}

// Mega ugly but there isn't really any other way of doing this with non-regular files...
static bool do_external_copy(std::string_view source, std::string_view destination)
{
    pid_t pid;
    int status;
    std::error_code error;

    ((char *)destination.data())[destination.size()] = '\0';
    if (std::filesystem::is_directory(destination) && !std::filesystem::remove(destination, error) && error.value() == ENOTEMPTY)
        return true;
    if ((pid = fork()) == 0) {
        ((char *)source.data())[source.size()] = '\0';
        execl("/bin/cp", "mv", "-rp", source.data(), destination.data(), NULL);
        std::cerr << "Failed to exec cp !\n";
        std::exit(1);
    }
    waitpid(pid, &status, 0);
    if (!WIFEXITED(status) || WEXITSTATUS(status))
        return true;
    if ((pid = fork()) == 0) {
        ((char *)source.data())[source.size()] = '\0';
        execl("/bin/rm", "mv", "-rf", source.data(), NULL);
        std::cerr << "Failed to exec cp !\n";
        std::exit(1);
    }
    waitpid(pid, &status, 0);
    return !WIFEXITED(status) || WEXITSTATUS(status);
}

static bool do_move(const mv_options &opts, std::string_view source, std::string_view destination)
{    
    if (!opts.f_flag && std::filesystem::exists(destination)) {
        bool should_ask = false;
        auto status = std::filesystem::status(destination);

        if (opts.i_flag) {
            std::cerr << fmt::format("overwrite {} ? ", destination);
            should_ask = true;
        }
        
        int read_character;
        if (should_ask) {
            if ((read_character = std::cin.get()) != std::cin.eof() && read_character != '\n')
                while (std::cin.get() != '\n' && !std::cin.fail())
                    continue;
            if (read_character != 'y')
                return false;
        }
    }

    std::error_code error;
    std::filesystem::rename(source, destination, error);

    if (!error)
        return false;

    if (error.value() != EXDEV) {
        std::cerr << fmt::format("mv: rename({}, {}): {}\n", source, destination, error.message());
        return true;
    }

    if (!std::filesystem::is_regular_file(source, error))
        return do_external_copy(source, destination);
    std::filesystem::copy_file(source, destination, std::filesystem::copy_options::overwrite_existing, error);
    if (static_cast<bool>(error) || !std::filesystem::remove(source, error))
        return (true);
    return (false);
}

int main(int argc, char **argv)
{
    int getopt_result;
    mv_options opts;

    g_argv0 = argv[0];
    while ((getopt_result = getopt(argc, argv, "fi")) != -1)
        switch (getopt_result) {
        case 'f':
            opts.f_flag = true;
            opts.i_flag = false;
            break;
        case 'i':
            opts.i_flag = true;
            opts.f_flag = false;
            break;
        default:
            std::exit(EXIT_FAILURE);
        }

    std::vector<std::string_view> file_list(argv + optind, argv + argc);
    if (file_list.size() <= 1) {
        if (file_list.size() == 0)
            print_error_and_die("missing file operand");
        else
            print_error_and_die("missing destination file operand after {}", file_list[0]);
    }

    assert(file_list.size() >= 2);
    std::string_view last_file = file_list.back();

    if (std::filesystem::is_directory(last_file))
        file_list.pop_back();
    else if (file_list.size() > 2)
        print_error_and_die("target {} is not a directory", last_file);
    else
        std::exit(do_move(opts, file_list[0], file_list[1]));

    std::string output_directory = std::string(last_file) + '/';

    bool is_failed = false;

    for (auto i : file_list) {
        auto i_basename = get_basename(i);
        is_failed |= do_move(opts, i, output_directory + std::string(i_basename));
    }
    return is_failed;
}
