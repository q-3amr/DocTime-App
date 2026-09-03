namespace LuminosHrm.Models;
public class EmployeeDirectoryViewModel { public IReadOnlyList<Employee> Employees {get;set;}=Array.Empty<Employee>(); public string Search {get;set;}=""; public string Department {get;set;}="All departments"; public int ActiveCount => Employees.Count(e=>e.Status=="Active"); public IEnumerable<string> Departments => Employees.Select(e=>e.Dept).Distinct().Order(); }
