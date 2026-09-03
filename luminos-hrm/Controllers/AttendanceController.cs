using Microsoft.AspNetCore.Mvc; using LuminosHrm.Models; using LuminosHrm.Services;
namespace LuminosHrm.Controllers;
public class AttendanceController(IEmployeeService service):Controller { public IActionResult Index(DateTime? date){var d=date?.Date??DateTime.Today;return View(new AttendanceViewModel{Date=d,Employees=service.GetAll(),Records=service.GetAttendance(d)});} [HttpPost] public IActionResult Update(AttendanceRecord record){service.UpdateAttendance(record);return Json(new{ok=true});} }
