@tool
extends Node

class_name Log

signal log_message(level:LogLevel,message:String)

enum LogLevel {
    DEBUG,
    INFO,
    WARN,
    ERROR,
    FATAL,
}

var CURRENT_LOG_LEVEL=LogLevel.INFO
var write_logs:bool = false
var log_path:String = "res://game.log"
var _config

var _prefix=""
var _default_args={}

var _file

var _subsystems := {}

func _ready():
    _set_loglevel(Config.get_var("log-level","debug"))
    
func _set_loglevel(level:String):
    logger("setting log level",{"level":level},LogLevel.INFO)
    match level.to_lower():
        "debug":
            CURRENT_LOG_LEVEL = LogLevel.DEBUG
        "info":
            CURRENT_LOG_LEVEL = LogLevel.INFO
        "warn":
            CURRENT_LOG_LEVEL = LogLevel.WARN
        "error":
            CURRENT_LOG_LEVEL = LogLevel.ERROR
        "fatal":
            CURRENT_LOG_LEVEL = LogLevel.FATAL

func _get_current_loglevel(subsystem):
    if subsystem in _subsystems:
        return _subsystems[subsystem]
    
    return CURRENT_LOG_LEVEL

func set_subsytem_log_level(subsystem, loglevel : int) -> void:
    _subsystems[subsystem] = loglevel

func with(prefix:String="",args:Dictionary={}) ->Log :
    var l = Log.new()
    l.CURRENT_LOG_LEVEL = self.CURRENT_LOG_LEVEL
    l._prefix = prefix
    for k in args:
        l._default_args[k] = args[k]
    return l

func logger(message:String,values,log_level=LogLevel.INFO, subsystem = null):
    if _get_current_loglevel(subsystem) > log_level :
        return
    
    var local_prefix = _prefix
    if subsystem != null:
        local_prefix = "[%s]%s" % [subsystem, _prefix]
        
    var log_msg_format = "{level} [{time}]{prefix} {message} "

    var now = Time.get_datetime_dict_from_system(true)
    
    var msg = log_msg_format.format(
        {
            "prefix":local_prefix,
            "message":message,
            "time":"{day}/{month}/{year} {hour}:{minute}:{second}".format(now),
            "level":LogLevel.keys()[log_level]
        })
    
    
    match typeof(values):
        TYPE_ARRAY:
            if values.size() > 0:
                msg += "["
                for k in values:
                    msg += "{k},".format({"k":JSON.stringify(k)})
                msg = msg.left(msg.length()-1)+"]"
        TYPE_DICTIONARY:
            for k in _default_args:
                values[k] = _default_args[k]
            if values.size() > 0:
                msg += "{"
                for k in values:
                    if typeof(values[k]) == TYPE_OBJECT && values[k] != null:
                        msg += '"{k}":{v},'.format({"k":k,"v":JSON.stringify(JsonData.to_dict(values[k],false))})
                    else:
                        msg += '"{k}":{v},'.format({"k":k,"v":JSON.stringify(values[k])})
                msg = msg.left(msg.length()-1)+"}"
        TYPE_PACKED_BYTE_ARRAY:
            if values == null:
                msg += JSON.stringify(null)
            else:
                msg += JSON.stringify(JsonData.unmarshal_bytes_to_dict(values))
        TYPE_OBJECT:
            if values == null:
                msg += JSON.stringify(null)
            else:
                msg += JSON.stringify(JsonData.to_dict(values,false))
        TYPE_NIL:
            msg += JSON.stringify(null)
        _:
            msg += JSON.stringify(values)
    if OS.get_main_thread_id() != OS.get_thread_caller_id() and log_level == LogLevel.DEBUG:
        print("[%d]Cannot retrieve debug info outside the main thread:\n\t%s" % [OS.get_thread_caller_id(),msg])
        return
    _write_logs(msg)
    emit_signal("log_message", log_level, msg)
    match log_level:
        LogLevel.DEBUG:
            print(msg)
        LogLevel.INFO:
            print(msg)
        LogLevel.WARN:
            print(msg)
            push_warning(msg)
            print_stack()
        LogLevel.ERROR:
            push_error(msg)
            printerr(msg)
            print_stack()
            print_tree()
        LogLevel.FATAL:
            push_error(msg)
            printerr(msg)
            print_stack()
            print_tree()
            get_tree().quit()
        _:
            print(msg)
            
func debug(message:String,values={},subsystem=null):
    call_thread_safe("logger",message,values,LogLevel.DEBUG,subsystem)

func info(message:String,values={},subsystem=null):
    call_thread_safe("logger",message,values,LogLevel.INFO,subsystem)

func warn(message:String,values={},subsystem=null):
    call_thread_safe("logger",message,values,LogLevel.WARN,subsystem)

func error(message:String,values={},subsystem=null):
    call_thread_safe("logger",message,values,LogLevel.ERROR,subsystem)

func fatal(message:String,values={},subsystem=null):
    call_thread_safe("logger",message,values,LogLevel.FATAL,subsystem)
    

func _write_logs(message:String):
    if !write_logs:
        return
    if _file == null:
        _file = FileAccess.open(log_path,FileAccess.WRITE)
    _file.store_line(message)
    pass
    
