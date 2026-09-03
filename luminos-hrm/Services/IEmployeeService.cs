using LuminosHrm.Models;
namespace LuminosHrm.Services;
public interface IEmployeeService { IReadOnlyList<Employee> GetAll(); Employee? Get(int id); Employee Add(Employee employee); void Update(Employee employee); IReadOnlyList<AttendanceRecord> GetAttendance(DateTime date); void UpdateAttendance(AttendanceRecord record); }
