import { withBase } from '../utils/paths';

const homeLocalePathPattern = /^\/(?:en|ca|gl|eu)\/?$/;

export function isHomepagePath(pathname: string) {
  return pathname === '/' || homeLocalePathPattern.test(pathname);
}

export function getAgentDiscoveryLinkValues(basePath = '/') {
  const discoveryTargets = [
    ['api-catalog', '/.well-known/api-catalog', 'application/linkset+json'],
    ['service-doc', '/api/docs', 'text/html'],
    ['describedby', '/llms.txt', 'text/plain'],
    ['oauth-protected-resource', '/.well-known/oauth-protected-resource', 'application/json'],
    ['agent-skills', '/.well-known/agent-skills/index.json', 'application/json'],
  ] as const;

  return discoveryTargets.map(
    ([rel, path, type]) => `<${withBase(path, basePath)}>; rel="${rel}"; type="${type}"`,
  );
}
