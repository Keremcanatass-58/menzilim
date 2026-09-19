using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Menzilim.Infrastructure.Data;

namespace Menzilim.Tests.Api;

/// <summary>
/// Gerçek API'yi (Program.cs, JWT, endpoint'ler, seed) SQL Server yerine
/// SQLite in-memory veritabanıyla ayağa kaldırır. Her örnek izole bir DB'dir.
/// </summary>
public sealed class MenzilimApiFactory : WebApplicationFactory<Program>
{
    private readonly SqliteConnection _connection = new("DataSource=:memory:");

    public MenzilimApiFactory()
    {
        _connection.Open();

        // Uygulama açılışta seed çalıştırdığı için şema önceden oluşturulur.
        using var db = CreateDbContext();
        db.Database.EnsureCreated();
    }

    public MenzilimDbContext CreateDbContext() =>
        new(new DbContextOptionsBuilder<MenzilimDbContext>()
            .UseSqlite(_connection)
            .Options);

    // Yalnızca testler için; gerçek bir secret değildir. Testlerin geliştirici
    // makinesindeki User Secrets'a bağımlı olmaması için kullanılır.
    private const string TestJwtKey = "menzilim-integration-tests-only-jwt-signing-key";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseSetting("Jwt:Key", TestJwtKey);

        builder.ConfigureTestServices(services =>
        {
            services.RemoveAll<DbContextOptions<MenzilimDbContext>>();
            services.RemoveAll<IDbContextOptionsConfiguration<MenzilimDbContext>>();

            services.AddDbContext<MenzilimDbContext>(options =>
                options.UseSqlite(_connection));
        });
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);

        if (disposing)
        {
            _connection.Dispose();
        }
    }
}
