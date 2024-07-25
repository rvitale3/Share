import pexpect

def run_ssh_command(host, port, username, password, command):
    ssh_command = 'ssh -p {} {}@{}'.format(port, username, host)
    
    try:
        # Spawn an SSH process
        child = pexpect.spawn(ssh_command)
        
        # Wait for the password prompt
        child.expect('password:')
        
        # Send the password
        child.sendline(password)
        
        # Wait for the command prompt
        child.expect(r'\$ ')
        
        # Send the command
        child.sendline(command)
        
        # Wait for the command to complete
        child.expect(r'\$ ')
        
        # Capture output
        output = child.before
        errors = child.after
        
        # Return output and errors
        return output, errors
        
    except pexpect.EOF as e:
        return '', str(e)
    except pexpect.TIMEOUT as e:
        return '', str(e)

# Example usage
host = 'your.server.com'
port = 22
username = 'your_username'
password = 'your_password'
command = 'your_command_here'

output, errors = run_ssh_command(host, port, username, password, command)

print("Output:")
print(output)

if errors:
    print("Errors:")
    print(errors)
