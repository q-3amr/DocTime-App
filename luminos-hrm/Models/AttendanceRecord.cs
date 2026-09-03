namespace LuminosHrm.Models;
public class AttendanceRecord { public int EmployeeId {get;set;} public DateTime Date {get;set;} public string Status {get;set;}="Present"; public string CheckIn {get;set;}="09:00"; public string CheckOut {get;set;}="17:30"; public double HoursWorked {get;set;}=8.5; public string Note {get;set;}=""; }
