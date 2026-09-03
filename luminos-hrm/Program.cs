using LuminosHrm.Services;
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllersWithViews();
builder.Services.AddSingleton<IEmployeeService, EmployeeService>();
var app = builder.Build();
if (!app.Environment.IsDevelopment()) { app.UseExceptionHandler("/Employee/Error"); app.UseHsts(); }
app.UseHttpsRedirection(); app.UseStaticFiles(); app.UseRouting();
app.MapControllerRoute(name: "default", pattern: "{controller=Employee}/{action=Index}/{id?}");
app.Run();
